import { Injectable, inject } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { SaludServidor } from '../models/salud-servidor.model';
import { EstadoServidorRepository } from '../repositories/estado-servidor.repository';
import { EstadoServidorStore } from '../estado-servidor.store';

@Injectable({ providedIn: 'root' })
export class VerificarEstadoServidorUseCase implements UseCase<void, SaludServidor> {
    private estadoServidorRepository = inject(EstadoServidorRepository);
    private estadoServidorStore = inject(EstadoServidorStore);

    execute(): Observable<SaludServidor> {
        this.estadoServidorStore.iniciarVerificacion();

        // El repositorio nunca falla: también devuelve un modelo cuando el
        // servidor está caído, así que el store siempre queda con un resultado
        return this.estadoServidorRepository.verificar().pipe(
            tap(salud => this.estadoServidorStore.establecer(salud))
        );
    }
}
