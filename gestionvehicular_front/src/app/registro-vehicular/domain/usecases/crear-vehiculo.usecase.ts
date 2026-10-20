import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { CrearVehiculoRequest } from '../models/crear-vehiculo-request.model';
import { Vehiculo } from '../models/vehiculo.model';
import { RegistroVehicularRepository } from '../repositories/registro-vehicular.repository';

@Injectable({ providedIn: 'root' })
export class CrearVehiculoUseCase implements UseCase<CrearVehiculoRequest, Vehiculo> {
    private registroVehicularRepository = inject(RegistroVehicularRepository);

    execute(params: CrearVehiculoRequest): Observable<Vehiculo> {
        // La placa se normaliza a mayúsculas y sin espacios antes de enviarla
        const request = params.withCopy({
            placa: params.placa.trim().toUpperCase().replace(/\s+/g, ''),
            conductor: params.conductor.trim()
        });

        return this.registroVehicularRepository.crear(request);
    }
}
