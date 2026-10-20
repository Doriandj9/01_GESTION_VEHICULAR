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
import { ParqueaderosStore } from '../../parqueaderos/domain/parqueaderos.store';
import { ListarParqueaderosUseCase } from '../../parqueaderos/domain/usecases/listar-parqueaderos.usecase';
import { ActualizarVehiculoRequest } from '../domain/models/actualizar-vehiculo-request.model';
import { CrearVehiculoRequest } from '../domain/models/crear-vehiculo-request.model';
import { Vehiculo } from '../domain/models/vehiculo.model';
import { ActualizarVehiculoUseCase } from '../domain/usecases/actualizar-vehiculo.usecase';
import { CrearVehiculoUseCase } from '../domain/usecases/crear-vehiculo.usecase';
import { ListarVehiculosUseCase } from '../domain/usecases/listar-vehiculos.usecase';
import { VehiculosStore } from '../domain/vehiculos.store';

// -----------------------------------------------------------
// RegistroVehicularPage (Orquestador del módulo de registro vehicular)
// -----------------------------------------------------------
@Component({
    selector: 'app-registro-vehicular',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './registro-vehicular.page.html',
    styleUrls: ['./registro-vehicular.page.css']
})
export class RegistroVehicularPage implements OnInit {
    private listarVehiculosUseCase = inject(ListarVehiculosUseCase);
    private crearVehiculoUseCase = inject(CrearVehiculoUseCase);
    private actualizarVehiculoUseCase = inject(ActualizarVehiculoUseCase);
    private listarParqueaderosUseCase = inject(ListarParqueaderosUseCase);
    private logoutUseCase = inject(LogoutUseCase);
    private dialogo = inject(DialogoResultadoService);
    private loader = inject(LoaderService);
    private router = inject(Router);

    /** Estado global de la sesión, de los vehículos y de los parqueaderos */
    protected readonly sesion = inject(SesionStore);
    protected readonly store = inject(VehiculosStore);
    protected readonly parqueaderosStore = inject(ParqueaderosStore);

    /** Identidad de la entidad, tomada de las variables de ambiente */
    protected readonly entidad = environment.entidad;

    /**
     * Datos del formulario. Son `signal` porque `formularioValido` es un
     * `computed`: con propiedades planas el cálculo no se vuelve a evaluar y el
     * botón quedaría deshabilitado para siempre.
     */
    readonly placa = signal('');
    readonly conductor = signal('');
    readonly codParqueadero = signal('');

    /** Indica que el registro está en curso */
    readonly cargando = signal(false);

    /** Indica que se está trayendo el listado */
    readonly cargandoListado = signal(false);

    /** Código del vehículo cuyo estado se está cambiando */
    readonly actualizando = signal<number | null>(null);

    /** Código del vehículo cuyo QR está ampliado */
    readonly qrAmpliado = signal<number | null>(null);

    /** Los tres campos son obligatorios para la api */
    readonly formularioValido = computed(() =>
        this.placa().trim().length > 0
        && this.conductor().trim().length > 0
        && this.codParqueadero().length > 0
    );

    /** Sin parqueaderos no se puede registrar un vehículo */
    readonly faltanParqueaderos = computed(() => this.parqueaderosStore.total() === 0);

    ngOnInit(): void {
        this.cargarVehiculos();
        this.cargarParqueaderos();
    }

    /** Trae el listado completo de vehículos */
    cargarVehiculos(): void {
        this.cargandoListado.set(true);

        this.listarVehiculosUseCase.execute().subscribe({
            next: () => this.cargandoListado.set(false),
            error: (fallo: unknown) => {
                this.cargandoListado.set(false);
                this.dialogo.error(aErrorApi(fallo), 'No se pudo cargar el listado');
            }
        });
    }

    /** Registra un vehículo nuevo y muestra su código QR */
    onFormSubmit(): void {
        if (this.cargando() || !this.formularioValido()) { return; }

        this.cargando.set(true);
        this.loader.display(true);

        const request = new CrearVehiculoRequest(
            this.placa(),
            this.conductor(),
            Number(this.codParqueadero())
        );

        this.crearVehiculoUseCase.execute(request).subscribe({
            next: vehiculo => {
                this.finalizar();
                this.store.agregar(vehiculo);
                this.limpiarFormulario();
                this.qrAmpliado.set(vehiculo.codVehiculo);
                this.dialogo.exito(
                    `El vehículo ${vehiculo.placa} quedó asignado a ${this.nombreParqueadero(vehiculo)}. Su código QR ya está disponible en el listado.`,
                    'Vehículo registrado'
                );
            },
            error: (fallo: unknown) => {
                // El diálogo muestra el mensaje de la api y sus validaciones
                this.finalizar();
                this.dialogo.error(aErrorApi(fallo), 'No se pudo registrar el vehículo');
            }
        });
    }

    /** Cambia el estado de un vehículo ya registrado */
    cambiarEstado(vehiculo: Vehiculo, estado: EstadoOperativo): void {
        if (this.actualizando() !== null || vehiculo.estado === estado) { return; }

        this.actualizando.set(vehiculo.codVehiculo);
        this.loader.display(true);

        const request = new ActualizarVehiculoRequest(vehiculo.codVehiculo, undefined, undefined, estado);

        this.actualizarVehiculoUseCase.execute(request).subscribe({
            next: actualizado => {
                this.terminarActualizacion();
                this.store.reemplazar(actualizado);
                this.dialogo.exito(
                    `El vehículo ${actualizado.placa} quedó en estado ${actualizado.estado}.`,
                    'Estado actualizado'
                );
            },
            error: (fallo: unknown) => {
                this.terminarActualizacion();
                this.dialogo.error(aErrorApi(fallo), 'No se pudo actualizar el vehículo');
            }
        });
    }

    /** Muestra u oculta el código QR ampliado de un vehículo */
    alternarQr(vehiculo: Vehiculo): void {
        this.qrAmpliado.update(actual => actual === vehiculo.codVehiculo ? null : vehiculo.codVehiculo);
    }

    /** Indica si el QR del vehículo está ampliado */
    qrVisible(vehiculo: Vehiculo): boolean {
        return this.qrAmpliado() === vehiculo.codVehiculo;
    }

    /** Nombre del parqueadero asignado; el código si todavía no está en memoria */
    nombreParqueadero(vehiculo: Vehiculo): string {
        const parqueadero = this.parqueaderosStore.buscar(vehiculo.codParqueadero);

        return parqueadero ? parqueadero.nombre : `Parqueadero ${vehiculo.codParqueadero}`;
    }

    /** Vuelve al panel de administración */
    irAlDashboard(): void {
        this.router.navigate(['/dashboard']);
    }

    /** Abre el módulo de parqueaderos para registrar el primero */
    irAParqueaderos(): void {
        this.router.navigate(['/parqueaderos']);
    }

    /** Cierra la sesión y vuelve al login */
    cerrarSesion(): void {
        this.loader.display(true);

        this.logoutUseCase.execute().subscribe({
            next: () => this.volverAlLogin(),
            error: () => this.volverAlLogin()
        });
    }

    /** Indica si la fila del vehículo está esperando respuesta de la api */
    filaEnEspera(vehiculo: Vehiculo): boolean {
        return this.actualizando() === vehiculo.codVehiculo;
    }

    /** Clases del distintivo según el estado del vehículo */
    clasesEstado(estado: EstadoOperativo): string {
        return estado === 'ACTIVO'
            ? 'bg-primario/10 text-primario-oscuro'
            : 'bg-carbon/10 text-carbon/60';
    }

    /** Nombre del archivo al descargar el QR */
    nombreArchivoQr(vehiculo: Vehiculo): string {
        return `qr-${vehiculo.placa}.png`;
    }

    /**
     * Carga los parqueaderos solo para poblar el selector. Se usa la versión en
     * caché porque el módulo de parqueaderos ya pudo haberlos traído.
     */
    private cargarParqueaderos(): void {
        this.listarParqueaderosUseCase.executeEnCache().subscribe({
            // Si falla, el formulario avisa que no hay parqueaderos disponibles
            error: () => { }
        });
    }

    private limpiarFormulario(): void {
        this.placa.set('');
        this.conductor.set('');
        this.codParqueadero.set('');
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
