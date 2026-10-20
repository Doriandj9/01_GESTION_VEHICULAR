import { Injectable, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { AuthTokensResponse } from '../../base/apiTypes';

/** Claves con las que se persisten los tokens en el navegador */
const CLAVE_JWT = 'gv_jwt';
const CLAVE_REFRESH_TOKEN = 'gv_refresh_token';

/**
 * Guarda los tokens de la sesión. El jwt vive en `sessionStorage` (muere al
 * cerrar la pestaña) y el refresh token en `localStorage` (sobrevive al cierre).
 * Todo acceso al almacenamiento va protegido porque puede estar bloqueado.
 */
@Injectable({ providedIn: 'root' })
export class TokenStore {
    private readonly _jwt = signal<string | null>(leer(sessionStorage, CLAVE_JWT));
    private readonly _refreshToken = signal<string | null>(leer(localStorage, CLAVE_REFRESH_TOKEN));

    /** Jwt vigente o null si no hay sesión */
    public readonly jwt = this._jwt.asReadonly();

    /** Refresh token vigente o null si no hay sesión */
    public readonly refreshToken = this._refreshToken.asReadonly();

    /**
     * Refresco en curso. Se comparte entre todas las peticiones que reciben 401
     * al mismo tiempo para no golpear el endpoint de refresh varias veces.
     */
    public refrescoEnCurso: Observable<AuthTokensResponse> | null = null;

    /** Persiste los tokens devueltos por la api */
    guardarTokens(jwt: string, refreshToken: string): void {
        this._jwt.set(jwt);
        this._refreshToken.set(refreshToken);
        escribir(sessionStorage, CLAVE_JWT, jwt);
        escribir(localStorage, CLAVE_REFRESH_TOKEN, refreshToken);
    }

    /** Borra los tokens de memoria y del navegador */
    limpiar(): void {
        this._jwt.set(null);
        this._refreshToken.set(null);
        this.refrescoEnCurso = null;
        borrar(sessionStorage, CLAVE_JWT);
        borrar(localStorage, CLAVE_REFRESH_TOKEN);
    }
}

function leer(almacen: Storage, clave: string): string | null {
    try {
        return almacen.getItem(clave);
    } catch {
        return null;
    }
}

function escribir(almacen: Storage, clave: string, valor: string): void {
    try {
        almacen.setItem(clave, valor);
    } catch {
        // El almacenamiento puede estar bloqueado: la sesión sigue en memoria
    }
}

function borrar(almacen: Storage, clave: string): void {
    try {
        almacen.removeItem(clave);
    } catch {
        // Sin acción: no hay nada que limpiar si el almacenamiento no está disponible
    }
}
