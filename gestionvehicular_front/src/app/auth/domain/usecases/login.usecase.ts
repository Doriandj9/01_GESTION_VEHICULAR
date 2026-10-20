import { Injectable } from '@angular/core';
import { Observable, switchMap, tap } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { LoginRequest } from '../models/login-request.model';
import { UsuarioDetalle } from '../models/usuario-detalle.model';
import { AuthRepository } from '../repositories/auth.repository';
import { SesionStore } from '../sesion.store';
import { TokenStore } from '../token.store';

@Injectable({ providedIn: 'root' })
export class LoginUseCase implements UseCase<LoginRequest, UsuarioDetalle> {
    constructor(
        private authRepository: AuthRepository,
        private tokenStore: TokenStore,
        private sesionStore: SesionStore
    ) { }

    execute(params: LoginRequest): Observable<UsuarioDetalle> {
        // 1. Autentica y guarda los tokens; 2. consulta el detalle del usuario
        //    con el jwt recién obtenido y lo deja en el estado global
        return this.authRepository.login(params).pipe(
            tap(tokens => this.tokenStore.guardarTokens(tokens.jwt, tokens.refreshToken)),
            switchMap(() => this.authRepository.getUsuarioDetalle()),
            tap(usuario => this.sesionStore.guardarUsuario(usuario))
        );
    }
}
