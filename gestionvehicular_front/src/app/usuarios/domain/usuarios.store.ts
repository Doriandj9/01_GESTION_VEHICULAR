import { Injectable, computed, signal } from '@angular/core';
import { Usuario } from './models/usuario.model';

/**
 * Estado en memoria del módulo de usuarios. Se llena con `GET /usuarios` y se
 * mantiene al día con lo que se registra o se edita, para no volver a pedir el
 * listado completo después de cada acción.
 */
@Injectable({ providedIn: 'root' })
export class UsuariosStore {
    private readonly _usuarios = signal<Usuario[]>([]);

    readonly usuarios = this._usuarios.asReadonly();

    /** Cantidad de usuarios registrados */
    readonly total = computed(() => this._usuarios().length);

    /** Reemplaza la lista completa con lo que devolvió la api */
    establecer(usuarios: Usuario[]): void {
        this._usuarios.set(usuarios);
    }

    /** Agrega un usuario nuevo al inicio de la lista */
    agregar(usuario: Usuario): void {
        this._usuarios.update(actuales => [usuario, ...actuales]);
    }

    /** Reemplaza un usuario ya listado por su versión actualizada */
    reemplazar(usuario: Usuario): void {
        this._usuarios.update(actuales =>
            actuales.map(actual => actual.codUsuarios === usuario.codUsuarios ? usuario : actual)
        );
    }

    /** Vacía la lista (por ejemplo al cerrar sesión) */
    limpiar(): void {
        this._usuarios.set([]);
    }
}
