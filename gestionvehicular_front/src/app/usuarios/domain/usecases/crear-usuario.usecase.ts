import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { CrearUsuarioRequest } from '../models/crear-usuario-request.model';
import { Usuario } from '../models/usuario.model';
import { UsuariosRepository } from '../repositories/usuarios.repository';

@Injectable({ providedIn: 'root' })
export class CrearUsuarioUseCase implements UseCase<CrearUsuarioRequest, Usuario> {
    private usuariosRepository = inject(UsuariosRepository);

    execute(params: CrearUsuarioRequest): Observable<Usuario> {
        // Se normaliza el texto antes de enviarlo: el correo viaja en minúsculas
        const request = params.withCopy({
            nombre: params.nombre.trim(),
            correo: params.correo.trim().toLowerCase()
        });

        return this.usuariosRepository.crear(request);
    }
}
