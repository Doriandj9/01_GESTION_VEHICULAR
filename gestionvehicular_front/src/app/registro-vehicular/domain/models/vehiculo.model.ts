import { EstadoOperativo } from '../../../base/apiTypes';

/**
 * Vehículo registrado en un parqueadero. Los cuatro endpoints de
 * `registro_vehicular` devuelven el mismo esquema (`VehiculoResponseCreate`),
 * que a diferencia de usuarios y parqueaderos **sí trae el estado**, y además
 * un código QR en base64.
 */
export class Vehiculo {
    constructor(
        public readonly codVehiculo: number,
        public readonly placa: string,
        public readonly conductor: string,
        public readonly estado: EstadoOperativo,
        public readonly codParqueadero: number,
        public readonly qrCodeBase64: string
    ) { }

    // Compara por valor, no por referencia
    equals(otro: Vehiculo): boolean {
        return this.codVehiculo === otro.codVehiculo
            && this.placa === otro.placa
            && this.conductor === otro.conductor
            && this.estado === otro.estado
            && this.codParqueadero === otro.codParqueadero
            && this.qrCodeBase64 === otro.qrCodeBase64;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<Vehiculo>): Vehiculo {
        return new Vehiculo(
            cambios.codVehiculo ?? this.codVehiculo,
            cambios.placa ?? this.placa,
            cambios.conductor ?? this.conductor,
            cambios.estado ?? this.estado,
            cambios.codParqueadero ?? this.codParqueadero,
            cambios.qrCodeBase64 ?? this.qrCodeBase64
        );
    }

    /** Indica si el vehículo está habilitado para circular */
    estaActivo(): boolean {
        return this.estado === 'ACTIVO';
    }

    /** Indica si la api devolvió el código QR */
    tieneQr(): boolean {
        return this.qrCodeBase64.length > 0;
    }

    /**
     * Arma el `data:` que puede ir en el `src` de una imagen. La api devuelve el
     * base64 sin prefijo, pero se tolera que algún día lo incluya.
     */
    qrComoImagen(): string {
        return this.qrCodeBase64.startsWith('data:')
            ? this.qrCodeBase64
            : `data:image/png;base64,${this.qrCodeBase64}`;
    }
}
