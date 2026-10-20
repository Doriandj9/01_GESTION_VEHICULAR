import { EstadoOperativo } from '../../../base/apiTypes';

/**
 * Parqueadero tal como lo usa la ui. La api devuelve el mismo esquema
 * (`ParqueaderResponseCreate`) en el listado, la creación y la actualización, y
 * en ninguno de los tres incluye el estado, así que `estado` es `null` mientras
 * no se conozca. Es el mismo desfase que tiene el usuario.
 */
export class Parqueadero {
    constructor(
        public readonly codParqueadero: number,
        public readonly nombre: string,
        public readonly callePrincipal: string,
        public readonly calleSecundaria: string,
        public readonly latitud: number | null,
        public readonly longitud: number | null,
        public readonly urlDireccion: string,
        public readonly estado: EstadoOperativo | null
    ) { }

    // Compara por valor, no por referencia
    equals(otro: Parqueadero): boolean {
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
    withCopy(cambios: Partial<Parqueadero>): Parqueadero {
        return new Parqueadero(
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

    /** Dirección legible para mostrar en una sola línea */
    direccion(): string {
        return this.calleSecundaria
            ? `${this.callePrincipal} y ${this.calleSecundaria}`
            : this.callePrincipal;
    }

    /** Indica si el parqueadero tiene coordenadas registradas */
    tieneCoordenadas(): boolean {
        return this.latitud !== null && this.longitud !== null;
    }
}
