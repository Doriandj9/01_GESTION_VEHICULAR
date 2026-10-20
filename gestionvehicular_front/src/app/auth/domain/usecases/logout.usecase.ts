import { Injectable } from '@angular/core';
import { Observable, catchError, finalize, of } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { AuthRepository } from '../repositories/auth.repository';
import { SesionStore } from '../sesion.store';
import { TokenStore } from '../token.store';

@Injectable({ providedIn: 'root' })
export class LogoutUseCase implements UseCase<void, boolean> {
    constructor(
        private authRepository: AuthRepository,
        private tokenStore: TokenStore,
        private sesionStore: SesionStore
    ) { }

    execute(): Observable<boolean> {
        const refreshToken = this.tokenStore.refreshToken();

        // Sin refresh token solo queda limpiar el estado local
        if (!refreshToken) {
            this.sesionStore.cerrarSesion();
            return of(true);
        }

        // La sesión local se cierra siempre, aunque el backend falle
        return this.authRepository.logout(refreshToken).pipe(
            catchError(() => of(false)),
            finalize(() => this.sesionStore.cerrarSesion())
        );
    }
}
