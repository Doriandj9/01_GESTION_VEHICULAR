import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { CrearParqueaderoRequest } from '../models/crear-parqueadero-request.model';
import { Parqueadero } from '../models/parqueadero.model';
import { ParqueaderosRepository } from '../repositories/parqueaderos.repository';

@Injectable({ providedIn: 'root' })
export class CrearParqueaderoUseCase implements UseCase<CrearParqueaderoRequest, Parqueadero> {
    private parqueaderosRepository = inject(ParqueaderosRepository);

    execute(params: CrearParqueaderoRequest): Observable<Parqueadero> {
        // Se normaliza el texto antes de enviarlo
        const request = params.withCopy({
            nombre: params.nombre.trim(),
            callePrincipal: params.callePrincipal.trim(),
            calleSecundaria: params.calleSecundaria.trim(),
            urlDireccion: params.urlDireccion.trim()
        });

        return this.parqueaderosRepository.crear(request);
    }
}
