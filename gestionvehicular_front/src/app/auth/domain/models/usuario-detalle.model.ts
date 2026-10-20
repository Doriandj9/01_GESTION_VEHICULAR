import { EstadoUsuario, RolUsuario } from '../../../base/apiTypes';

// Usuario autenticado devuelto por `GET /usuarios/detalle`
export class UsuarioDetalle {
    constructor(
        public readonly codUsuarios: number,
        public readonly nombres: string,
        public readonly correo: string,
        public readonly estado: EstadoUsuario,
        public readonly rol: RolUsuario
    ) { }

    // Compara por valor, no por referencia
    equals(otro: UsuarioDetalle): boolean {
        return this.codUsuarios === otro.codUsuarios
            && this.nombres === otro.nombres
            && this.correo === otro.correo
            && this.estado === otro.estado
            && this.rol === otro.rol;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<UsuarioDetalle>): UsuarioDetalle {
        return new UsuarioDetalle(
            cambios.codUsuarios ?? this.codUsuarios,
            cambios.nombres ?? this.nombres,
            cambios.correo ?? this.correo,
            cambios.estado ?? this.estado,
            cambios.rol ?? this.rol
        );
    }

    /** Indica si el usuario tiene el rol de administrador */
    esAdministrador(): boolean {
        return this.rol === 'ADMINISTRADOR';
    }
}
