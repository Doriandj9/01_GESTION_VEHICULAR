import { CommonModule } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { environment } from '../../../environments';
import { EstadoOperativo } from '../../base/apiTypes';
import { aErrorApi } from '../../base/apiErrors';
import { DialogoResultadoService } from '../../base/components/dialogo-resultado/dialogo-resultado.service';
import { LoaderService } from '../../base/loadService';
import { SesionStore } from '../../auth/domain/sesion.store';
import { LogoutUseCase } from '../../auth/domain/usecases/logout.usecase';
import { ActualizarParqueaderoRequest } from '../domain/models/actualizar-parqueadero-request.model';
import { CrearParqueaderoRequest } from '../domain/models/crear-parqueadero-request.model';
import { Parqueadero } from '../domain/models/parqueadero.model';
import { ActualizarParqueaderoUseCase } from '../domain/usecases/actualizar-parqueadero.usecase';
import { CrearParqueaderoUseCase } from '../domain/usecases/crear-parqueadero.usecase';
import { ListarParqueaderosUseCase } from '../domain/usecases/listar-parqueaderos.usecase';
import { ParqueaderosStore } from '../domain/parqueaderos.store';

// -----------------------------------------------------------
// ParqueaderosPage (Orquestador del módulo de parqueaderos)
// -----------------------------------------------------------
@Component({
    selector: 'app-parqueaderos',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './parqueaderos.page.html',
    styleUrls: ['./parqueaderos.page.css']
})
export class ParqueaderosPage implements OnInit {
    private listarParqueaderosUseCase = inject(ListarParqueaderosUseCase);
    private crearParqueaderoUseCase = inject(CrearParqueaderoUseCase);
    private actualizarParqueaderoUseCase = inject(ActualizarParqueaderoUseCase);
    private logoutUseCase = inject(LogoutUseCase);
    private dialogo = inject(DialogoResultadoService);
    private loader = inject(LoaderService);
    private router = inject(Router);

    /** Estado global de la sesión y de los parqueaderos */
    protected readonly sesion = inject(SesionStore);
    protected readonly store = inject(ParqueaderosStore);

    /** Identidad de la entidad, tomada de las variables de ambiente */
    protected readonly entidad = environment.entidad;

    /**
     * Datos del formulario. Son `signal` porque `formularioValido` es un
     * `computed`: con propiedades planas el cálculo no se vuelve a evaluar y el
     * botón quedaría deshabilitado para siempre.
     */
    readonly nombre = signal('');
    readonly callePrincipal = signal('');
    readonly calleSecundaria = signal('');
    readonly latitud = signal('');
    readonly longitud = signal('');
    readonly urlDireccion = signal('');

    /** Indica que el registro está en curso */
    readonly cargando = signal(false);

    /** Indica que se está trayendo el listado */
    readonly cargandoListado = signal(false);

    /** Código del parqueadero cuyo estado se está cambiando */
    readonly actualizando = signal<number | null>(null);

    /** La api solo exige el nombre y la calle principal */
    readonly formularioValido = computed(() =>
        this.nombre().trim().length > 0 && this.callePrincipal().trim().length > 0
    );

    ngOnInit(): void {
        this.cargarParqueaderos();
    }

    /** Trae el listado completo de parqueaderos */
    cargarParqueaderos(): void {
        this.cargandoListado.set(true);

        this.listarParqueaderosUseCase.execute().subscribe({
            next: () => this.cargandoListado.set(false),
            error: (fallo: unknown) => {
                this.cargandoListado.set(false);
                this.dialogo.error(aErrorApi(fallo), 'No se pudo cargar el listado');
            }
        });
    }

    /** Registra un parqueadero nuevo */
    onFormSubmit(): void {
        if (this.cargando() || !this.formularioValido()) { return; }

        this.cargando.set(true);
        this.loader.display(true);

        const request = new CrearParqueaderoRequest(
            this.nombre(),
            this.callePrincipal(),
            this.calleSecundaria(),
            this.aNumero(this.latitud()),
            this.aNumero(this.longitud()),
            this.urlDireccion()
        );

        this.crearParqueaderoUseCase.execute(request).subscribe({
            next: parqueadero => {
                this.finalizar();
                this.store.agregar(parqueadero);
                this.limpiarFormulario();
                this.dialogo.exito(
                    `El parqueadero ${parqueadero.nombre} fue registrado en ${parqueadero.direccion()}.`,
                    'Parqueadero registrado'
                );
            },
            error: (fallo: unknown) => {
                // El diálogo muestra el mensaje de la api y sus validaciones
                this.finalizar();
                this.dialogo.error(aErrorApi(fallo), 'No se pudo registrar el parqueadero');
            }
        });
    }

    /** Cambia el estado de un parqueadero ya registrado */
    cambiarEstado(parqueadero: Parqueadero, estado: EstadoOperativo): void {
        if (this.actualizando() !== null || parqueadero.estado === estado) { return; }

        this.actualizando.set(parqueadero.codParqueadero);
        this.loader.display(true);

        const request = new ActualizarParqueaderoRequest(
            parqueadero.codParqueadero,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            estado
        );

        this.actualizarParqueaderoUseCase.execute(request).subscribe({
            next: actualizado => {
                this.terminarActualizacion();
                this.store.reemplazar(actualizado);
                this.dialogo.exito(
                    `El parqueadero ${actualizado.nombre} quedó en estado ${estado}.`,
                    'Estado actualizado'
                );
            },
            error: (fallo: unknown) => {
                this.terminarActualizacion();
                this.dialogo.error(aErrorApi(fallo), 'No se pudo actualizar el parqueadero');
            }
        });
    }

    /** Vuelve al panel de administración */
    irAlDashboard(): void {
        this.router.navigate(['/dashboard']);
    }

    /** Cierra la sesión y vuelve al login */
    cerrarSesion(): void {
        this.loader.display(true);

        this.logoutUseCase.execute().subscribe({
            next: () => this.volverAlLogin(),
            error: () => this.volverAlLogin()
        });
    }

    /** Indica si la fila del parqueadero está esperando respuesta de la api */
    filaEnEspera(parqueadero: Parqueadero): boolean {
        return this.actualizando() === parqueadero.codParqueadero;
    }

    /** Clases del distintivo según el estado del parqueadero */
    clasesEstado(estado: EstadoOperativo | null): string {
        if (estado === 'ACTIVO') {
            return 'bg-primario/10 text-primario-oscuro';
        }

        return 'bg-carbon/10 text-carbon/60';
    }

    /** Texto del distintivo; las respuestas de la api no informan el estado */
    textoEstado(estado: EstadoOperativo | null): string {
        return estado ?? 'sin dato';
    }

    /** Coordenadas legibles para la tabla */
    textoCoordenadas(parqueadero: Parqueadero): string {
        return parqueadero.tieneCoordenadas()
            ? `${parqueadero.latitud}, ${parqueadero.longitud}`
            : 'sin ubicación';
    }

    /**
     * Convierte el valor del formulario a número; `null` si está vacío o no es
     * válido. Acepta `unknown` porque un `input[type=number]` con `ngModel`
     * emite un `number` (o `null`), no el texto que se ve en pantalla: tratarlo
     * como texto lanzaba una excepción y dejaba el botón de registro muerto.
     */
    private aNumero(valor: unknown): number | null {
        if (typeof valor === 'number') {
            return Number.isFinite(valor) ? valor : null;
        }

        if (typeof valor !== 'string') { return null; }

        const limpio = valor.trim();

        if (!limpio) { return null; }

        const numero = Number(limpio);

        return Number.isFinite(numero) ? numero : null;
    }

    private limpiarFormulario(): void {
        this.nombre.set('');
        this.callePrincipal.set('');
        this.calleSecundaria.set('');
        this.latitud.set('');
        this.longitud.set('');
        this.urlDireccion.set('');
    }

    private finalizar(): void {
        this.cargando.set(false);
        this.loader.display(false);
    }

    private terminarActualizacion(): void {
        this.actualizando.set(null);
        this.loader.display(false);
    }

    private volverAlLogin(): void {
        this.loader.display(false);
        this.router.navigate(['/login']);
    }
}
