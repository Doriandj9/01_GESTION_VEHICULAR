import { EstadoUsuario, RolUsuario } from '../../../base/apiTypes';

/**
 * Petición de `PUT /usuarios/{id}`. Todos los campos del cuerpo son opcionales
 * en el backend: solo se envían los que se quieren modificar.
 */
export class ActualizarUsuarioRequest {
    constructor(
        public readonly codUsuarios: number,
        public readonly nombres?: string,
        public readonly correo?: string,
        public readonly rol?: RolUsuario,
        public readonly estado?: EstadoUsuario
    ) { }

    // Compara por valor, no por referencia
    equals(otro: ActualizarUsuarioRequest): boolean {
        return this.codUsuarios === otro.codUsuarios
            && this.nombres === otro.nombres
            && this.correo === otro.correo
            && this.rol === otro.rol
            && this.estado === otro.estado;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<ActualizarUsuarioRequest>): ActualizarUsuarioRequest {
        return new ActualizarUsuarioRequest(
            cambios.codUsuarios ?? this.codUsuarios,
            cambios.nombres ?? this.nombres,
            cambios.correo ?? this.correo,
            cambios.rol ?? this.rol,
            cambios.estado ?? this.estado
        );
    }
}
