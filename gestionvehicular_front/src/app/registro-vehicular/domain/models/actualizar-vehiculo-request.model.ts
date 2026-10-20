import { EstadoOperativo } from '../../../base/apiTypes';

/**
 * Petición de `PUT /registro_vehicular/{id}`. Todos los campos del cuerpo son
 * opcionales: solo se envían los que se quieren modificar.
 */
export class ActualizarVehiculoRequest {
    constructor(
        public readonly codVehiculo: number,
        public readonly placa?: string,
        public readonly conductor?: string,
        public readonly estado?: EstadoOperativo,
        public readonly codParqueadero?: number
    ) { }

    // Compara por valor, no por referencia
    equals(otro: ActualizarVehiculoRequest): boolean {
        return this.codVehiculo === otro.codVehiculo
            && this.placa === otro.placa
            && this.conductor === otro.conductor
            && this.estado === otro.estado
            && this.codParqueadero === otro.codParqueadero;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<ActualizarVehiculoRequest>): ActualizarVehiculoRequest {
        return new ActualizarVehiculoRequest(
            cambios.codVehiculo ?? this.codVehiculo,
            cambios.placa ?? this.placa,
            cambios.conductor ?? this.conductor,
            cambios.estado ?? this.estado,
            cambios.codParqueadero ?? this.codParqueadero
        );
    }
}
