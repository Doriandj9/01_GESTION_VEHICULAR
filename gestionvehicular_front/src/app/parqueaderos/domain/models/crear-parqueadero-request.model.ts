// Petición de `POST /parqueaderos`. Solo `nombre` y `callePrincipal` son obligatorios.
export class CrearParqueaderoRequest {
    constructor(
        public readonly nombre: string,
        public readonly callePrincipal: string,
        public readonly calleSecundaria: string,
        public readonly latitud: number | null,
        public readonly longitud: number | null,
        public readonly urlDireccion: string
    ) { }

    // Compara por valor, no por referencia
    equals(otro: CrearParqueaderoRequest): boolean {
        return this.nombre === otro.nombre
            && this.callePrincipal === otro.callePrincipal
            && this.calleSecundaria === otro.calleSecundaria
            && this.latitud === otro.latitud
            && this.longitud === otro.longitud
            && this.urlDireccion === otro.urlDireccion;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<CrearParqueaderoRequest>): CrearParqueaderoRequest {
        return new CrearParqueaderoRequest(
            cambios.nombre ?? this.nombre,
            cambios.callePrincipal ?? this.callePrincipal,
            cambios.calleSecundaria ?? this.calleSecundaria,
            cambios.latitud ?? this.latitud,
            cambios.longitud ?? this.longitud,
            cambios.urlDireccion ?? this.urlDireccion
        );
    }
}
