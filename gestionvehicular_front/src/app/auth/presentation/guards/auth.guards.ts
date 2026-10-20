import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { catchError, map, of } from 'rxjs';
import { RolUsuario } from '../../../base/apiTypes';
import { SesionStore } from '../../domain/sesion.store';
import { TokenStore } from '../../domain/token.store';
import { GetUsuarioDetalleUseCase } from '../../domain/usecases/get-usuario-detalle.usecase';

/**
 * Exige sesión activa. Si el usuario no está en memoria pero hay un jwt
 * guardado (por ejemplo tras recargar la página), lo recupera de la api.
 * Además obliga a cambiar la clave mientras el estado sea INICIAL.
 */
export const sesionGuard: CanActivateFn = () => {
    const tokenStore = inject(TokenStore);
    const sesionStore = inject(SesionStore);
    const getUsuarioDetalle = inject(GetUsuarioDetalleUseCase);
    const router = inject(Router);

    if (!tokenStore.jwt()) {
        return router.createUrlTree(['/login']);
    }

    return getUsuarioDetalle.execute().pipe(
        map(usuario => {
            if (!usuario) {
                return router.createUrlTree(['/login']);
            }

            // Mientras la clave sea la inicial no se puede navegar a otra parte
            if (usuario.estado === 'INICIAL') {
                return router.createUrlTree(['/cambiar-clave']);
            }

            return true;
        }),
        catchError(() => {
            sesionStore.cerrarSesion();
            return of(router.createUrlTree(['/login']));
        })
    );
};

/**
 * Permite el acceso solo al rol indicado. Se usa después de `sesionGuard`,
 * que ya garantizó que el usuario esté cargado.
 */
export function rolGuard(rolPermitido: RolUsuario): CanActivateFn {
    return () => {
        const sesionStore = inject(SesionStore);
        const router = inject(Router);

        return sesionStore.usuario()?.rol === rolPermitido
            ? true
            : router.createUrlTree(['/login']);
    };
}

/**
 * Protege la pantalla de cambio de clave: solo entra quien tiene sesión, y
 * quien ya cambió su clave es devuelto a su pantalla.
 */
export const claveInicialGuard: CanActivateFn = () => {
    const tokenStore = inject(TokenStore);
    const getUsuarioDetalle = inject(GetUsuarioDetalleUseCase);
    const router = inject(Router);

    if (!tokenStore.jwt()) {
        return router.createUrlTree(['/login']);
    }

    return getUsuarioDetalle.execute().pipe(
        map(usuario => {
            if (!usuario) {
                return router.createUrlTree(['/login']);
            }

            return usuario.estado === 'INICIAL' ? true : router.createUrlTree(['/dashboard']);
        }),
        catchError(() => of(router.createUrlTree(['/login'])))
    );
};
