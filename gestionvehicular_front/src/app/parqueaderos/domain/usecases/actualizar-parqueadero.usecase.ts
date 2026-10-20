import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { ActualizarParqueaderoRequest } from '../models/actualizar-parqueadero-request.model';
import { Parqueadero } from '../models/parqueadero.model';
import { ParqueaderosRepository } from '../repositories/parqueaderos.repository';

@Injectable({ providedIn: 'root' })
export class ActualizarParqueaderoUseCase implements UseCase<ActualizarParqueaderoRequest, Parqueadero> {
    private parqueaderosRepository = inject(ParqueaderosRepository);

    execute(params: ActualizarParqueaderoRequest): Observable<Parqueadero> {
        return this.parqueaderosRepository.actualizar(params);
    }
}
