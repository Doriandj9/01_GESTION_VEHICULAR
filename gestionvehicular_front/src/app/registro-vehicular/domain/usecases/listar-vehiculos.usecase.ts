import { Injectable, inject } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { Vehiculo } from '../models/vehiculo.model';
import { RegistroVehicularRepository } from '../repositories/registro-vehicular.repository';
import { VehiculosStore } from '../vehiculos.store';

@Injectable({ providedIn: 'root' })
export class ListarVehiculosUseCase implements UseCase<void, Vehiculo[]> {
    private registroVehicularRepository = inject(RegistroVehicularRepository);
    private vehiculosStore = inject(VehiculosStore);

    execute(): Observable<Vehiculo[]> {
        // El listado es la fuente de verdad: reemplaza lo que haya en memoria
        return this.registroVehicularRepository.listar().pipe(
            tap(vehiculos => this.vehiculosStore.establecer(vehiculos))
        );
    }
}
