import { EstadoUsuario, RolUsuario } from '../../../base/apiTypes';

/**
 * Usuario del sistema tal como lo usa la ui. Unifica las tres respuestas del
 * backend: `GET /usuarios` y `POST /usuarios` devuelven `UsuarioResponse`
 * (sin estado) y `PUT /usuarios/{id}` devuelve la entidad completa con el rol
 * como objeto. El repositorio se encarga de normalizarlas.
 *
 * `estado` es `null` cuando la api no lo informó: el listado no lo trae, así
 * que no se puede suponer.
 */
export class Usuario {
    constructor(
        public readonly codUsuarios: number,
        public readonly nombres: string,
        public readonly correo: string,
        public readonly rol: RolUsuario,
        public readonly estado: EstadoUsuario | null
    ) { }

    // Compara por valor, no por referencia
    equals(otro: Usuario): boolean {
        return this.codUsuarios === otro.codUsuarios
            && this.nombres === otro.nombres
            && this.correo === otro.correo
            && this.rol === otro.rol
            && this.estado === otro.estado;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<Usuario>): Usuario {
        return new Usuario(
            cambios.codUsuarios ?? this.codUsuarios,
            cambios.nombres ?? this.nombres,
            cambios.correo ?? this.correo,
            cambios.rol ?? this.rol,
            cambios.estado ?? this.estado
        );
    }

    /** Indica si el usuario todavía no ha cambiado su clave inicial */
    tieneClaveInicial(): boolean {
        return this.estado === 'INICIAL';
    }

    /** Indica si la api no informó el estado del usuario */
    estadoDesconocido(): boolean {
        return this.estado === null;
    }
}
