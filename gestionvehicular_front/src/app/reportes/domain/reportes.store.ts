import { Injectable, computed, signal } from '@angular/core';
import { TipoMovimiento } from '../../base/apiTypes';
import { MovimientoReporte } from './models/movimiento-reporte.model';

/** Valor del filtro de tipo; `TODOS` significa que no se filtra nada */
export type FiltroTipoMovimiento = TipoMovimiento | 'TODOS';

/**
 * Estado en memoria del reporte de movimientos. Guarda lo que devolvió la api
 * tal cual (`movimientos`) y aparte el filtro por tipo, que **se resuelve en el
 * cliente**: la api no acepta `tipoMovimiento` como parámetro en ninguno de los
 * dos reportes, así que filtrar aquí evita volver a pedir los datos cada vez
 * que el usuario cambia entre entradas y salidas.
 */
@Injectable({ providedIn: 'root' })
export class ReportesStore {
    private readonly _movimientos = signal<MovimientoReporte[]>([]);
    private readonly _filtroTipo = signal<FiltroTipoMovimiento>('TODOS');

    /** Lo que devolvió la api, sin filtrar */
    readonly movimientos = this._movimientos.asReadonly();

    /** Tipo por el que se está filtrando */
    readonly filtroTipo = this._filtroTipo.asReadonly();

    /** Lo que debe pintar la tabla: el reporte con el filtro de tipo aplicado */
    readonly movimientosFiltrados = computed(() => {
        const tipo = this._filtroTipo();

        if (tipo === 'TODOS') { return this._movimientos(); }

        return this._movimientos().filter(movimiento => movimiento.tipoMovimiento === tipo);
    });

    /** Cantidad de movimientos que trajo la api */
    readonly total = computed(() => this._movimientos().length);

    /** Cantidad de movimientos visibles con el filtro puesto */
    readonly totalFiltrado = computed(() => this.movimientosFiltrados().length);

    /** Entradas del reporte completo, sin importar el filtro */
    readonly totalEntradas = computed(() =>
        this._movimientos().filter(movimiento => movimiento.esEntrada()).length
    );

    /** Salidas del reporte completo, sin importar el filtro */
    readonly totalSalidas = computed(() => this.total() - this.totalEntradas());

    /** Indica si el filtro está escondiendo filas */
    readonly filtroActivo = computed(() => this._filtroTipo() !== 'TODOS');

    /** Reemplaza el reporte con lo que devolvió la api */
    establecer(movimientos: MovimientoReporte[]): void {
        this._movimientos.set(movimientos);
    }

    /** Cambia el tipo por el que se filtra en el cliente */
    filtrarPorTipo(tipo: FiltroTipoMovimiento): void {
        this._filtroTipo.set(tipo);
    }

    /** Vacía el reporte y deja el filtro en su valor inicial */
    limpiar(): void {
        this._movimientos.set([]);
        this._filtroTipo.set('TODOS');
    }
}
