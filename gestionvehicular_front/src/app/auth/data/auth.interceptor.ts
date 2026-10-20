import { HttpClient, HttpErrorResponse, HttpInterceptorFn, HttpRequest } from '@angular/common/http';
import { inject } from '@angular/core';
import { Observable, catchError, finalize, shareReplay, switchMap, tap, throwError } from 'rxjs';
import { environment } from '../../../environments';
import { AuthTokensResponse } from '../../base/apiTypes';
import { SesionStore } from '../domain/sesion.store';
import { TokenStore } from '../domain/token.store';

/** Rutas públicas: no llevan Authorization ni se reintentan */
const RUTAS_PUBLICAS = ['/auth', '/auth/refresh'];

/**
 * Rutas que sí llevan Authorization pero nunca se reintentan: en ellas un 401
 * es un error del negocio (clave actual incorrecta, token ya cerrado) y no un
 * jwt caducado, así que renovar el token dejaría al usuario fuera de la sesión.
 */
const RUTAS_SIN_REINTENTO = ['/auth/change-password', '/auth/logout'];

/**
 * Agrega el header Authorization a las peticiones a la api. Si el backend
 * responde 401, renueva el jwt con `POST /auth/refresh` y reintenta la petición
 * una sola vez. Si el refresh también responde 401, marca la sesión como
 * expirada para que la ui pida iniciar sesión de nuevo.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
    // Las peticiones a otros dominios no se tocan
    if (!req.url.startsWith(environment.api.url)) {
        return next(req);
    }

    const tokenStore = inject(TokenStore);
    const sesionStore = inject(SesionStore);
    const http = inject(HttpClient);

    // El chequeo de salud es infraestructura pública: no lleva token y un error
    // suyo no debe disparar el refresco ni expirar la sesión
    if (esChequeoDeSalud(req.url) || esRutaPublica(req.url)) {
        return next(req);
    }

    const peticion = conAutorizacion(req, tokenStore.jwt());

    if (esRutaSinReintento(req.url)) {
        return next(peticion);
    }

    return next(peticion).pipe(
        catchError((error: HttpErrorResponse) => {
            // El backend responde 401 o 403 cuando el jwt no sirve
            if (error.status !== 401 && error.status !== 403) {
                return throwError(() => error);
            }

            return reintentarConTokenRenovado(req, next, http, tokenStore, sesionStore, error);
        })
    );
};

/**
 * Indica si la url es el chequeo de salud del actuator. No se resuelve con
 * `rutaRelativa` porque esa ruta cuelga de la url base, fuera del prefijo de
 * versión que esa función recorta.
 */
function esChequeoDeSalud(url: string): boolean {
    return url.startsWith(environment.api.urlSalud);
}

/** Indica si la url corresponde a un endpoint público de la api */
function esRutaPublica(url: string): boolean {
    return RUTAS_PUBLICAS.includes(rutaRelativa(url));
}

/** Indica si la url no debe reintentarse tras un error de autorización */
function esRutaSinReintento(url: string): boolean {
    return RUTAS_SIN_REINTENTO.includes(rutaRelativa(url));
}

/** Quita la url base de la api para quedarse con la ruta del endpoint */
function rutaRelativa(url: string): string {
    return url.replace(`${environment.api.url}${environment.api.version}`, '');
}

/** Clona la petición agregando el header Authorization */
function conAutorizacion<T>(req: HttpRequest<T>, jwt: string | null): HttpRequest<T> {
    if (!jwt) {
        return req;
    }

    return req.clone({ setHeaders: { Authorization: `Bearer ${jwt}` } });
}

/** Renueva el jwt y vuelve a lanzar la petición original una única vez */
function reintentarConTokenRenovado(
    req: HttpRequest<unknown>,
    next: (peticion: HttpRequest<unknown>) => Observable<any>,
    http: HttpClient,
    tokenStore: TokenStore,
    sesionStore: SesionStore,
    errorOriginal: HttpErrorResponse
): Observable<any> {
    const refreshToken = tokenStore.refreshToken();

    // Sin refresh token no hay nada que renovar
    if (!refreshToken) {
        sesionStore.expirarSesion();
        return throwError(() => errorOriginal);
    }

    return refrescarToken(http, tokenStore, sesionStore, refreshToken).pipe(
        switchMap(tokens => next(conAutorizacion(req, tokens.jwt)))
    );
}

/** Llama a `POST /auth/refresh` compartiendo un único refresco entre peticiones */
function refrescarToken(
    http: HttpClient,
    tokenStore: TokenStore,
    sesionStore: SesionStore,
    refreshToken: string
): Observable<AuthTokensResponse> {
    if (tokenStore.refrescoEnCurso) {
        return tokenStore.refrescoEnCurso;
    }

    const url = `${environment.api.url}${environment.api.version}/auth/refresh`;

    tokenStore.refrescoEnCurso = http.post<AuthTokensResponse>(url, { token: refreshToken }).pipe(
        tap(tokens => tokenStore.guardarTokens(tokens.jwt, tokens.refreshToken)),
        catchError((error: HttpErrorResponse) => {
            // Si el refresco falla el usuario debe volver a iniciar sesión.
            // Se cubre cualquier error porque el backend responde 500 ante un
            // refresh token inválido, no solo 401.
            sesionStore.expirarSesion();
            return throwError(() => error);
        }),
        finalize(() => tokenStore.refrescoEnCurso = null),
        shareReplay(1)
    );

    return tokenStore.refrescoEnCurso;
}
