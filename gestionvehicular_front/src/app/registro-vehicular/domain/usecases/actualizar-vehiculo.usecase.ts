import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { ActualizarVehiculoRequest } from '../models/actualizar-vehiculo-request.model';
import { Vehiculo } from '../models/vehiculo.model';
import { RegistroVehicularRepository } from '../repositories/registro-vehicular.repository';

@Injectable({ providedIn: 'root' })
export class ActualizarVehiculoUseCase implements UseCase<ActualizarVehiculoRequest, Vehiculo> {
    private registroVehicularRepository = inject(RegistroVehicularRepository);

    execute(params: ActualizarVehiculoRequest): Observable<Vehiculo> {
        return this.registroVehicularRepository.actualizar(params);
    }
}
