import { Entorno } from './environment.model';

/** Entorno de producción. Las claves reales se reemplazan en el despliegue */
export const environment: Entorno = {
    produccion: true,
    nombreAmbiente: 'produccion',
    api: {
        url: '',
        version: '/api/v1',
        urlSalud: '/actuator/health',
        tiempoEspera: 20000
    },
    entidad: {
        nombre: 'Gobierno Autónomo Descentralizado Municipal de La Joya de los Sachas',
        alias: 'GADMJS'
    }
};
