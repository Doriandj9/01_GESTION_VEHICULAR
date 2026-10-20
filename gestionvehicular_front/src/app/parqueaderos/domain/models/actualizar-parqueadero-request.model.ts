import { EstadoOperativo } from '../../../base/apiTypes';

/**
 * Petición de `PUT /parqueaderos/{id}`. Todos los campos del cuerpo son
 * opcionales: solo se envían los que se quieren modificar. Es el único endpoint
 * de parqueaderos que acepta `estado`.
 */
export class ActualizarParqueaderoRequest {
    constructor(
        public readonly codParqueadero: number,
        public readonly nombre?: string,
        public readonly callePrincipal?: string,
        public readonly calleSecundaria?: string,
        public readonly latitud?: number,
        public readonly longitud?: number,
        public readonly urlDireccion?: string,
        public readonly estado?: EstadoOperativo
    ) { }

    // Compara por valor, no por referencia
    equals(otro: ActualizarParqueaderoRequest): boolean {
        return this.codParqueadero === otro.codParqueadero
            && this.nombre === otro.nombre
            && this.callePrincipal === otro.callePrincipal
            && this.calleSecundaria === otro.calleSecundaria
            && this.latitud === otro.latitud
            && this.longitud === otro.longitud
            && this.urlDireccion === otro.urlDireccion
            && this.estado === otro.estado;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<ActualizarParqueaderoRequest>): ActualizarParqueaderoRequest {
        return new ActualizarParqueaderoRequest(
            cambios.codParqueadero ?? this.codParqueadero,
            cambios.nombre ?? this.nombre,
            cambios.callePrincipal ?? this.callePrincipal,
            cambios.calleSecundaria ?? this.calleSecundaria,
            cambios.latitud ?? this.latitud,
            cambios.longitud ?? this.longitud,
            cambios.urlDireccion ?? this.urlDireccion,
            cambios.estado ?? this.estado
        );
    }
}
