import { Injectable } from '@angular/core';
import { Observable, switchMap, tap } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { ChangePasswordRequest } from '../models/change-password-request.model';
import { UsuarioDetalle } from '../models/usuario-detalle.model';
import { AuthRepository } from '../repositories/auth.repository';
import { SesionStore } from '../sesion.store';
import { TokenStore } from '../token.store';

@Injectable({ providedIn: 'root' })
export class ChangePasswordUseCase implements UseCase<ChangePasswordRequest, UsuarioDetalle> {
    constructor(
        private authRepository: AuthRepository,
        private tokenStore: TokenStore,
        private sesionStore: SesionStore
    ) { }

    execute(params: ChangePasswordRequest): Observable<UsuarioDetalle> {
        // El cambio devuelve tokens nuevos; luego se refresca el usuario para
        // que su estado deje de ser INICIAL en el estado global
        return this.authRepository.changePassword(params).pipe(
            tap(tokens => this.tokenStore.guardarTokens(tokens.jwt, tokens.refreshToken)),
            switchMap(() => this.authRepository.getUsuarioDetalle()),
            tap(usuario => this.sesionStore.guardarUsuario(usuario))
        );
    }
}
