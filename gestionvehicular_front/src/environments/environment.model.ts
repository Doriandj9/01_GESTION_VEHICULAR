/**
 * Contrato del entorno de la aplicación.
 * Equivalente al archivo `.env` en otras plataformas: Angular resuelve
 * el entorno en tiempo de compilación mediante `fileReplacements`.
 */
export interface Entorno {
    /** Indica si la compilación es de producción */
    produccion: boolean;
    /** Nombre del ambiente activo */
    nombreAmbiente: 'desarrollo' | 'produccion';
    /** Configuración de la api principal */
    api: ConfiguracionApi;
    /** Entidad dueña del sistema */
    entidad: DatosEntidad;
}

/** Identidad de la entidad a la que pertenece el proyecto */
export interface DatosEntidad {
    /** Nombre completo de la entidad */
    nombre: string;
    /** Alias o siglas de la entidad */
    alias: string;
}

/** Datos de conexión y claves de la api */
export interface ConfiguracionApi {
    /** Url base de la api (sin barra final) */
    url: string;
    /** Prefijo de versión de los recursos */
    version: string;
    /**
     * Url completa del chequeo de salud del backend. Va aparte de `url` porque
     * el actuator cuelga de la raíz del servidor, **fuera** del prefijo de
     * versión, y porque en desarrollo se consume como ruta relativa: el backend
     * no manda cabeceras CORS en `/actuator/**`, así que el dev-server la
     * redirige con `proxy.conf.json` y el navegador la ve como propia.
     */
    urlSalud: string;
    /** Tiempo máximo de espera en milisegundos */
    tiempoEspera: number;
}
