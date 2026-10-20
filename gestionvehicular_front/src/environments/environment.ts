import { Entorno } from './environment.model';

/** Entorno de desarrollo (valor por defecto) */
export const environment: Entorno = {
    produccion: false,
    nombreAmbiente: 'desarrollo',
    api: {
        url: 'http://localhost:8080',
        version: '/api/v1.0',
        // Relativa a propósito: la resuelve el proxy del dev-server
        urlSalud: '/actuator/health',
        tiempoEspera: 30000
    },
    entidad: {
        nombre: 'Gobierno Autónomo Descentralizado Municipal de La Joya de los Sachas',
        alias: 'GADMJS'
    }
};
