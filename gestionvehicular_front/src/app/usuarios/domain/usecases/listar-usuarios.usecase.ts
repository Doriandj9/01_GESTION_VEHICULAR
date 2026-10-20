import { Injectable, inject } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { Usuario } from '../models/usuario.model';
import { UsuariosRepository } from '../repositories/usuarios.repository';
import { UsuariosStore } from '../usuarios.store';

@Injectable({ providedIn: 'root' })
export class ListarUsuariosUseCase implements UseCase<void, Usuario[]> {
    private usuariosRepository = inject(UsuariosRepository);
    private usuariosStore = inject(UsuariosStore);

    execute(): Observable<Usuario[]> {
        // El listado es la fuente de verdad: reemplaza lo que haya en memoria
        return this.usuariosRepository.listar().pipe(
            tap(usuarios => this.usuariosStore.establecer(usuarios))
        );
    }
}
