import { CommonModule } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { environment } from '../../../environments';
import { aErrorApi } from '../../base/apiErrors';
import { DialogoResultadoService } from '../../base/components/dialogo-resultado/dialogo-resultado.service';
import { LoaderService } from '../../base/loadService';
import { SesionStore } from '../../auth/domain/sesion.store';
import { LogoutUseCase } from '../../auth/domain/usecases/logout.usecase';
import { MovimientoReporte } from '../domain/models/movimiento-reporte.model';
import { ReportePorFechasRequest } from '../domain/models/reporte-por-fechas-request.model';
import { ReporteTodosRequest } from '../domain/models/reporte-todos-request.model';
import { ObtenerReportePorFechasUseCase } from '../domain/usecases/obtener-reporte-por-fechas.usecase';
import { ObtenerReporteTodosUseCase } from '../domain/usecases/obtener-reporte-todos.usecase';
import { FiltroTipoMovimiento, ReportesStore } from '../domain/reportes.store';

/** Criterio con el que se consulta la api */
export type CriterioReporte = 'TODOS' | 'FECHAS';

// -----------------------------------------------------------
// ReportesPage (Orquestador del módulo de reportes)
// -----------------------------------------------------------
@Component({
    selector: 'app-reportes',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './reportes.page.html',
    styleUrls: ['./reportes.page.css']
})
export class ReportesPage implements OnInit {
    private obtenerReporteTodosUseCase = inject(ObtenerReporteTodosUseCase);
    private obtenerReportePorFechasUseCase = inject(ObtenerReportePorFechasUseCase);
    private logoutUseCase = inject(LogoutUseCase);
    private dialogo = inject(DialogoResultadoService);
    private loader = inject(LoaderService);
    private router = inject(Router);

    /** Estado global de la sesión y del reporte */
    protected readonly sesion = inject(SesionStore);
    protected readonly store = inject(ReportesStore);

    /** Identidad de la entidad, tomada de las variables de ambiente */
    protected readonly entidad = environment.entidad;

    /**
     * Datos del formulario de consulta. Son `signal` porque `consultaValida` es
     * un `computed`: con propiedades planas el cálculo no se vuelve a evaluar y
     * el botón quedaría deshabilitado para siempre.
     */
    readonly criterio = signal<CriterioReporte>('TODOS');
    readonly cantidad = signal('');
    readonly fechaInicial = signal('');
    readonly fechaFinal = signal('');

    /** Indica que la consulta a la api está en curso */
    readonly cargando = signal(false);

    /** Indica si ya se consultó al menos una vez, para distinguir "sin datos" de "sin consultar" */
    readonly consultado = signal(false);

    /** Opciones del filtro de tipo, que se resuelve en el cliente */
    readonly tiposDisponibles: FiltroTipoMovimiento[] = ['TODOS', 'ENTRADA', 'SALIDA'];

    /** El rango de fechas exige las dos fechas y en orden; el reporte completo no exige nada */
    readonly consultaValida = computed(() => {
        if (this.criterio() === 'TODOS') { return true; }

        const inicial = this.fechaInicial();
        const final = this.fechaFinal();

        return inicial.length > 0 && final.length > 0 && inicial <= final;
    });

    /** Avisa que el rango está al revés mientras se escribe */
    readonly rangoInvertido = computed(() =>
        this.criterio() === 'FECHAS'
        && this.fechaInicial().length > 0
        && this.fechaFinal().length > 0
        && this.fechaInicial() > this.fechaFinal()
    );

    ngOnInit(): void {
        // Se arranca con el reporte de los últimos movimientos para no abrir la
        // pantalla vacía; el histórico completo puede ser muy grande
        this.cantidad.set('50');
        this.consultar();
    }

    /** Consulta la api con el criterio elegido */
    consultar(): void {
        if (this.cargando() || !this.consultaValida()) { return; }

        this.cargando.set(true);
        this.loader.display(true);

        let consulta: Observable<MovimientoReporte[]>;

        // Si armar la petición falla, hay que soltar `cargando` igual: con el
        // botón atado a esa señal, dejarla en `true` lo deshabilita para siempre
        try {
            consulta = this.criterio() === 'FECHAS'
                ? this.obtenerReportePorFechasUseCase.execute(
                    new ReportePorFechasRequest(this.fechaInicial(), this.fechaFinal())
                )
                : this.obtenerReporteTodosUseCase.execute(
                    new ReporteTodosRequest(this.aNumero(this.cantidad()))
                );
        } catch (fallo: unknown) {
            this.finalizar();
            this.dialogo.error(aErrorApi(fallo), 'No se pudo generar el reporte');
            return;
        }

        consulta.subscribe({
            next: () => {
                this.finalizar();
                this.consultado.set(true);
            },
            error: (fallo: unknown) => {
                // El diálogo muestra el mensaje de la api y sus validaciones
                this.finalizar();
                this.consultado.set(true);
                this.dialogo.error(aErrorApi(fallo), 'No se pudo generar el reporte');
            }
        });
    }

    /**
     * Guarda la cantidad escrita. Pasa por aquí y no por `cantidad.set` directo
     * porque un `input[type=number]` con `ngModel` emite un `number` o `null`,
     * y la señal es de texto: meterle otro tipo rompía el envío del formulario.
     */
    actualizarCantidad(valor: unknown): void {
        this.cantidad.set(valor === null || valor === undefined ? '' : String(valor));
    }

    /**
     * Cambia el filtro por tipo de movimiento. No vuelve a llamar a la api: los
     * dos reportes no aceptan `tipoMovimiento` como parámetro, así que el
     * filtro se aplica sobre lo que ya está en memoria.
     */
    filtrarPorTipo(tipo: FiltroTipoMovimiento): void {
        this.store.filtrarPorTipo(tipo);
    }

    /** Cambia el criterio de consulta y limpia lo que no aplica */
    cambiarCriterio(criterio: CriterioReporte): void {
        if (this.criterio() === criterio) { return; }

        this.criterio.set(criterio);

        if (criterio === 'TODOS') {
            this.fechaInicial.set('');
            this.fechaFinal.set('');
        }
    }

    /** Indica si el filtro de tipo está en el valor indicado */
    tipoSeleccionado(tipo: FiltroTipoMovimiento): boolean {
        return this.store.filtroTipo() === tipo;
    }

    /** Clases del botón del filtro de tipo según esté o no seleccionado */
    clasesFiltroTipo(tipo: FiltroTipoMovimiento): string {
        return this.tipoSeleccionado(tipo)
            ? 'border-primario bg-primario text-white'
            : 'border-carbon/15 bg-white text-carbon/70 hover:border-primario hover:text-primario';
    }

    /** Clases del distintivo según el tipo del movimiento */
    clasesTipo(movimiento: MovimientoReporte): string {
        return movimiento.esEntrada()
            ? 'bg-primario/10 text-primario-oscuro'
            : 'bg-carbon/10 text-carbon/70';
    }

    /** Ubicación del registro legible para la tabla */
    textoUbicacion(movimiento: MovimientoReporte): string {
        return movimiento.tieneUbicacionRegistro()
            ? `${movimiento.latitudRegistro}, ${movimiento.longitudRegistro}`
            : 'sin ubicación';
    }

    /** Resumen de lo que se está viendo, con el filtro de tipo incluido */
    textoResumen(): string {
        if (!this.store.total()) { return 'Sin movimientos'; }

        if (!this.store.filtroActivo()) {
            return `${this.store.total()} movimientos`;
        }

        return `${this.store.totalFiltrado()} de ${this.store.total()} movimientos`;
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

    /**
     * Convierte el valor del formulario a número; `null` si está vacío o no es
     * válido. Acepta `unknown` porque un `input[type=number]` con `ngModel`
     * emite un `number` (o `null`), no el texto que se ve en pantalla.
     */
    private aNumero(valor: unknown): number | null {
        if (typeof valor === 'number') {
            return Number.isFinite(valor) ? Math.trunc(valor) : null;
        }

        if (typeof valor !== 'string') { return null; }

        const limpio = valor.trim();

        if (!limpio) { return null; }

        const numero = Number(limpio);

        return Number.isFinite(numero) ? Math.trunc(numero) : null;
    }

    private finalizar(): void {
        this.cargando.set(false);
        this.loader.display(false);
    }

    private volverAlLogin(): void {
        this.loader.display(false);
        this.router.navigate(['/login']);
    }
}
