import { Injectable, inject } from '@angular/core';
import { Observable, of, tap } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { Parqueadero } from '../models/parqueadero.model';
import { ParqueaderosRepository } from '../repositories/parqueaderos.repository';
import { ParqueaderosStore } from '../parqueaderos.store';

@Injectable({ providedIn: 'root' })
export class ListarParqueaderosUseCase implements UseCase<void, Parqueadero[]> {
    private parqueaderosRepository = inject(ParqueaderosRepository);
    private parqueaderosStore = inject(ParqueaderosStore);

    execute(): Observable<Parqueadero[]> {
        // El listado es la fuente de verdad: reemplaza lo que haya en memoria
        return this.parqueaderosRepository.listar().pipe(
            tap(parqueaderos => this.parqueaderosStore.establecer(parqueaderos))
        );
    }

    /**
     * Devuelve los parqueaderos sin volver a llamar a la api si ya están en
     * memoria. Lo usa el módulo de registro vehicular, que solo los necesita
     * para poblar el selector de parqueadero.
     */
    executeEnCache(): Observable<Parqueadero[]> {
        const enMemoria = this.parqueaderosStore.parqueaderos();

        return enMemoria.length ? of(enMemoria) : this.execute();
    }
}
