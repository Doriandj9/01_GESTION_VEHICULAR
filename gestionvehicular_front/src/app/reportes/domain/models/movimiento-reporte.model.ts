import { TipoMovimiento } from '../../../base/apiTypes';

/**
 * Una fila del reporte de movimientos. Es inmutable y viene aplanada igual que
 * la respuesta de la api: cada fila ya trae al usuario que registró, el
 * vehículo y el parqueadero, así que no necesita cruces con otros listados.
 */
export class MovimientoReporte {
    constructor(
        public readonly codUsuarioRegistro: number,
        public readonly nombreUsuarioRegistro: string,
        public readonly latitudRegistro: number | null,
        public readonly longitudRegistro: number | null,
        public readonly fechaRegistro: string,
        public readonly tipoMovimiento: TipoMovimiento,
        public readonly codVehiculo: number,
        public readonly placa: string,
        public readonly conductor: string,
        public readonly codParqueadero: number,
        public readonly nombreParqueadero: string,
        public readonly callePrincipalParqueadero: string,
        public readonly calleSecundariaParqueadero: string,
        public readonly latitudParqueadero: number | null,
        public readonly longitudParqueadero: number | null,
        public readonly urlDireccionParqueadero: string
    ) { }

    /**
     * Compara por valor. La api no expone un identificador propio del
     * movimiento, así que la identidad se arma con el vehículo, la fecha y el
     * tipo: no puede haber dos entradas del mismo vehículo en el mismo instante.
     */
    equals(otro: MovimientoReporte): boolean {
        return this.codVehiculo === otro.codVehiculo
            && this.fechaRegistro === otro.fechaRegistro
            && this.tipoMovimiento === otro.tipoMovimiento;
    }

    /** Devuelve una nueva instancia con los campos indicados */
    withCopy(cambios: Partial<MovimientoReporte>): MovimientoReporte {
        return new MovimientoReporte(
            cambios.codUsuarioRegistro ?? this.codUsuarioRegistro,
            cambios.nombreUsuarioRegistro ?? this.nombreUsuarioRegistro,
            cambios.latitudRegistro ?? this.latitudRegistro,
            cambios.longitudRegistro ?? this.longitudRegistro,
            cambios.fechaRegistro ?? this.fechaRegistro,
            cambios.tipoMovimiento ?? this.tipoMovimiento,
            cambios.codVehiculo ?? this.codVehiculo,
            cambios.placa ?? this.placa,
            cambios.conductor ?? this.conductor,
            cambios.codParqueadero ?? this.codParqueadero,
            cambios.nombreParqueadero ?? this.nombreParqueadero,
            cambios.callePrincipalParqueadero ?? this.callePrincipalParqueadero,
            cambios.calleSecundariaParqueadero ?? this.calleSecundariaParqueadero,
            cambios.latitudParqueadero ?? this.latitudParqueadero,
            cambios.longitudParqueadero ?? this.longitudParqueadero,
            cambios.urlDireccionParqueadero ?? this.urlDireccionParqueadero
        );
    }

    /** Clave estable para el `track` de la tabla */
    get clave(): string {
        return `${this.codVehiculo}-${this.fechaRegistro}-${this.tipoMovimiento}`;
    }

    /** Indica si el movimiento es un ingreso al parqueadero */
    esEntrada(): boolean {
        return this.tipoMovimiento === 'ENTRADA';
    }

    /** Dirección del parqueadero donde ocurrió el movimiento */
    direccionParqueadero(): string {
        return this.calleSecundariaParqueadero
            ? `${this.callePrincipalParqueadero} y ${this.calleSecundariaParqueadero}`
            : this.callePrincipalParqueadero;
    }

    /** Indica si el guardia registró coordenadas al escanear el QR */
    tieneUbicacionRegistro(): boolean {
        return this.latitudRegistro !== null && this.longitudRegistro !== null;
    }

    /** Fecha del registro como objeto `Date`; `null` si la api mandó algo ilegible */
    fechaComoObjeto(): Date | null {
        const fecha = new Date(this.fechaRegistro);

        return Number.isNaN(fecha.getTime()) ? null : fecha;
    }
}
