import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { ActualizarUsuarioRequest } from '../models/actualizar-usuario-request.model';
import { Usuario } from '../models/usuario.model';
import { UsuariosRepository } from '../repositories/usuarios.repository';

@Injectable({ providedIn: 'root' })
export class ActualizarUsuarioUseCase implements UseCase<ActualizarUsuarioRequest, Usuario> {
    private usuariosRepository = inject(UsuariosRepository);

    execute(params: ActualizarUsuarioRequest): Observable<Usuario> {
        return this.usuariosRepository.actualizar(params);
    }
}
