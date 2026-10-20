import { Injectable, computed, inject, signal } from '@angular/core';
import { UsuarioDetalle } from './models/usuario-detalle.model';
import { TokenStore } from './token.store';

/**
 * Estado global de la sesión. Guarda el usuario autenticado para que
 * cualquier funcionalidad pueda leerlo sin volver a consultar la api.
 */
@Injectable({ providedIn: 'root' })
export class SesionStore {
    private readonly tokenStore = inject(TokenStore);

    private readonly _usuario = signal<UsuarioDetalle | null>(null);
    private readonly _sesionExpirada = signal(false);

    /** Usuario autenticado actual (null si no hay sesión) */
    public readonly usuario = this._usuario.asReadonly();

    /** Indica que el token caducó y el usuario debe volver a iniciar sesión */
    public readonly sesionExpirada = this._sesionExpirada.asReadonly();

    /** Indica si existe una sesión activa */
    public readonly estaAutenticado = computed(() => this._usuario() !== null);

    /** Rol del usuario autenticado o cadena vacía si no hay sesión */
    public readonly rol = computed(() => this._usuario()?.rol ?? '');

    /** Guarda el usuario devuelto por la api */
    guardarUsuario(usuario: UsuarioDetalle): void {
        this._usuario.set(usuario);
        this._sesionExpirada.set(false);
    }

    /** Cierra la sesión y descarta los tokens */
    cerrarSesion(): void {
        this._usuario.set(null);
        this._sesionExpirada.set(false);
        this.tokenStore.limpiar();
    }

    /** Marca la sesión como expirada cuando el refresh token ya no sirve */
    expirarSesion(): void {
        this._usuario.set(null);
        this._sesionExpirada.set(true);
        this.tokenStore.limpiar();
    }

    /** Oculta el aviso de sesión expirada */
    descartarAvisoExpiracion(): void {
        this._sesionExpirada.set(false);
    }
}
