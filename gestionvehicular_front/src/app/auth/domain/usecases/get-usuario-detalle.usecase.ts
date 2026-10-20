import { Injectable } from '@angular/core';
import { Observable, of, tap } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { UsuarioDetalle } from '../models/usuario-detalle.model';
import { AuthRepository } from '../repositories/auth.repository';
import { SesionStore } from '../sesion.store';

@Injectable({ providedIn: 'root' })
export class GetUsuarioDetalleUseCase implements UseCase<void, UsuarioDetalle | null> {
    constructor(
        private authRepository: AuthRepository,
        private sesionStore: SesionStore
    ) { }

    execute(): Observable<UsuarioDetalle | null> {
        const usuarioEnMemoria = this.sesionStore.usuario();

        // Si el usuario ya está en el estado global no se vuelve a consultar
        if (usuarioEnMemoria) {
            return of(usuarioEnMemoria);
        }

        return this.authRepository.getUsuarioDetalle().pipe(
            tap(usuario => this.sesionStore.guardarUsuario(usuario))
        );
    }
}
