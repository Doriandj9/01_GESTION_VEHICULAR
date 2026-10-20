import { Injectable, inject } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { Vehiculo } from '../models/vehiculo.model';
import { RegistroVehicularRepository } from '../repositories/registro-vehicular.repository';
import { VehiculosStore } from '../vehiculos.store';

@Injectable({ providedIn: 'root' })
export class ObtenerVehiculoUseCase implements UseCase<number, Vehiculo> {
    private registroVehicularRepository = inject(RegistroVehicularRepository);
    private vehiculosStore = inject(VehiculosStore);

    execute(codVehiculo: number): Observable<Vehiculo> {
        // Lo que devuelva la api es más reciente que lo que haya en memoria
        return this.registroVehicularRepository.obtenerPorId(codVehiculo).pipe(
            tap(vehiculo => this.vehiculosStore.reemplazar(vehiculo))
        );
    }
}
