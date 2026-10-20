import { EstadoSalud } from '../../../base/apiTypes';

/**
 * Salud del backend tal como la entiende el front. Es inmutable y se arma
 * tanto con la respuesta correcta del actuator como con el error de la
 * petición: si el servidor no está levantado no hay cuerpo que leer, así que el
 * estado queda en `UNKNOWN` y el motivo viaja en `detalle`.
 */
export class SaludServidor {
    constructor(
        public readonly estado: EstadoSalud,
        public readonly grupos: string[],
        public readonly componentes: Record<string, EstadoSalud>,
        public readonly detalle: string
    ) { }

    /** Compara por valor, no por referencia */
    equals(otro: SaludServidor): boolean {
        return this.estado === otro.estado
            && this.detalle === otro.detalle
            && this.grupos.join() === otro.grupos.join()
            && JSON.stringify(this.componentes) === JSON.stringify(otro.componentes);
    }

    /** Devuelve una nueva instancia con los campos indicados */
    withCopy(cambios: Partial<SaludServidor>): SaludServidor {
        return new SaludServidor(
            cambios.estado ?? this.estado,
            cambios.grupos ?? this.grupos,
            cambios.componentes ?? this.componentes,
            cambios.detalle ?? this.detalle
        );
    }

    /** El servidor responde y se declara sano: es el único caso que deja pasar */
    estaArriba(): boolean {
        return this.estado === 'UP';
    }

    /** Indica si el servidor ni siquiera respondió la petición */
    estaInalcanzable(): boolean {
        return this.estado === 'UNKNOWN';
    }

    /** Componentes que no están sanos, como pares [nombre, estado] */
    componentesCaidos(): [string, EstadoSalud][] {
        return Object.entries(this.componentes)
            .filter(([, estado]) => estado !== 'UP');
    }
}
