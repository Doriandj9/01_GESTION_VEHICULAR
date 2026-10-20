import { Injectable, computed, signal } from '@angular/core';
import { Vehiculo } from './models/vehiculo.model';

/**
 * Estado en memoria de los vehículos registrados. Se llena con
 * `GET /registro_vehicular` y se mantiene al día con lo que se registra o se
 * edita, para no volver a pedir el listado completo después de cada acción.
 */
@Injectable({ providedIn: 'root' })
export class VehiculosStore {
    private readonly _vehiculos = signal<Vehiculo[]>([]);

    readonly vehiculos = this._vehiculos.asReadonly();

    /** Cantidad de vehículos registrados */
    readonly total = computed(() => this._vehiculos().length);

    /** Cantidad de vehículos habilitados para circular */
    readonly totalActivos = computed(() =>
        this._vehiculos().filter(vehiculo => vehiculo.estaActivo()).length
    );

    /** Reemplaza la lista completa con lo que devolvió la api */
    establecer(vehiculos: Vehiculo[]): void {
        this._vehiculos.set(vehiculos);
    }

    /** Agrega un vehículo nuevo al inicio de la lista */
    agregar(vehiculo: Vehiculo): void {
        this._vehiculos.update(actuales => [vehiculo, ...actuales]);
    }

    /** Reemplaza un vehículo ya listado por su versión actualizada */
    reemplazar(vehiculo: Vehiculo): void {
        this._vehiculos.update(actuales =>
            actuales.map(actual => actual.codVehiculo === vehiculo.codVehiculo ? vehiculo : actual)
        );
    }

    /** Vacía la lista (por ejemplo al cerrar sesión) */
    limpiar(): void {
        this._vehiculos.set([]);
    }
}
