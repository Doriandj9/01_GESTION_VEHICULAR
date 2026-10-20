// Petición de `POST /registro_vehicular`. Los tres campos son obligatorios.
export class CrearVehiculoRequest {
    constructor(
        public readonly placa: string,
        public readonly conductor: string,
        public readonly codParqueadero: number
    ) { }

    // Compara por valor, no por referencia
    equals(otro: CrearVehiculoRequest): boolean {
        return this.placa === otro.placa
            && this.conductor === otro.conductor
            && this.codParqueadero === otro.codParqueadero;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<CrearVehiculoRequest>): CrearVehiculoRequest {
        return new CrearVehiculoRequest(
            cambios.placa ?? this.placa,
            cambios.conductor ?? this.conductor,
            cambios.codParqueadero ?? this.codParqueadero
        );
    }
}
