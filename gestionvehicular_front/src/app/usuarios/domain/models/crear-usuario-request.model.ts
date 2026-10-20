import { RolUsuario } from '../../../base/apiTypes';

// Petición de `POST /usuarios`. El backend espera `nombre` en singular.
export class CrearUsuarioRequest {
    constructor(
        public readonly nombre: string,
        public readonly correo: string,
        public readonly rol: RolUsuario
    ) { }

    // Compara por valor, no por referencia
    equals(otro: CrearUsuarioRequest): boolean {
        return this.nombre === otro.nombre
            && this.correo === otro.correo
            && this.rol === otro.rol;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<CrearUsuarioRequest>): CrearUsuarioRequest {
        return new CrearUsuarioRequest(
            cambios.nombre ?? this.nombre,
            cambios.correo ?? this.correo,
            cambios.rol ?? this.rol
        );
    }
}
