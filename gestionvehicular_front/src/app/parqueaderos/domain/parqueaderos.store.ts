import { Injectable, computed, signal } from '@angular/core';
import { Parqueadero } from './models/parqueadero.model';

/**
 * Estado en memoria de los parqueaderos. Se llena con `GET /parqueaderos` y se
 * mantiene al día con lo que se registra o se edita, para no volver a pedir el
 * listado completo después de cada acción. También lo lee el módulo de registro
 * vehicular, que necesita los parqueaderos para asignarlos a un vehículo.
 */
@Injectable({ providedIn: 'root' })
export class ParqueaderosStore {
    private readonly _parqueaderos = signal<Parqueadero[]>([]);

    readonly parqueaderos = this._parqueaderos.asReadonly();

    /** Cantidad de parqueaderos registrados */
    readonly total = computed(() => this._parqueaderos().length);

    /** Reemplaza la lista completa con lo que devolvió la api */
    establecer(parqueaderos: Parqueadero[]): void {
        this._parqueaderos.set(parqueaderos);
    }

    /** Agrega un parqueadero nuevo al inicio de la lista */
    agregar(parqueadero: Parqueadero): void {
        this._parqueaderos.update(actuales => [parqueadero, ...actuales]);
    }

    /** Reemplaza un parqueadero ya listado por su versión actualizada */
    reemplazar(parqueadero: Parqueadero): void {
        this._parqueaderos.update(actuales =>
            actuales.map(actual =>
                actual.codParqueadero === parqueadero.codParqueadero ? parqueadero : actual
            )
        );
    }

    /** Busca un parqueadero por su código; `null` si no está en la lista */
    buscar(codParqueadero: number): Parqueadero | null {
        return this._parqueaderos().find(actual => actual.codParqueadero === codParqueadero) ?? null;
    }

    /** Vacía la lista (por ejemplo al cerrar sesión) */
    limpiar(): void {
        this._parqueaderos.set([]);
    }
}
