/**
 * Tipos globales de las respuestas de la api. Se declaran con `Type` porque
 * describen objetos y atributos, no contratos de clases. Cualquier capa puede
 * importarlos sin acoplarse a una funcionalidad concreta.
 */

/** Roles que maneja el backend */
export type RolUsuario = 'ADMINISTRADOR' | 'GUARDIA';

/** Estados que maneja el backend para un usuario */
export type EstadoUsuario = 'ACTIVO' | 'INACTIVO' | 'INICIAL';

/** Respuesta de `POST /auth` y `POST /auth/refresh` */
export type AuthTokensResponse = {
    jwt: string;
    refreshToken: string;
    jwtExpired: number;
};

/** Respuesta de `POST /auth/logout` */
export type LogoutResponse = {
    state: boolean;
    message: string;
};

/** Respuesta de `GET /usuarios/detalle`: datos del usuario autenticado con su rol */
export type UsuarioDetalleResponse = {
    codUsuarios: number;
    nombres: string;
    correo: string;
    estado: EstadoUsuario;
    rol: RolUsuario;
};

/**
 * Error estándar de la api (`ErrorRestGlobalResponse` del backend). Lo devuelven
 * todos los endpoints cuando algo falla.
 */
export type ErrorRestGlobalResponse = {
    /** Momento en que ocurrió el error */
    timestamp: string;
    /** Código http */
    status: number;
    /** Descripción corta del error */
    error: string;
    /** Errores por campo; llega `{}` cuando no hay validaciones fallidas */
    errors: Record<string, string>;
    /** Mensaje para el usuario: es lo que siempre se debe mostrar */
    message: string;
    /** Ruta del endpoint que falló */
    path: string;
};

/**
 * Esquema `UsuarioResponse` del backend: lo devuelven `POST /usuarios` y
 * `GET /usuarios`. Ojo: la petición manda `nombre` y la respuesta trae
 * `nombres`, y en ninguno de los dos casos viene el `estado`.
 */
export type UsuarioCreadoResponse = {
    codUsuario: number;
    nombres: string;
    correo: string;
    rol: RolUsuario;
    estado?: EstadoUsuario
};

/** Rol como lo devuelve la entidad completa del backend */
export type RolResponse = {
    codRol: number;
    rol: RolUsuario;
};

/**
 * Esquema `Usuario` del backend (entidad completa con auditoría): solo lo
 * devuelve `PUT /usuarios/{id}`, y ahí el rol llega como objeto.
 */
export type UsuarioResponse = {
    codUsuarios: number;
    nombres: string;
    correo: string;
    estado: EstadoUsuario;
    rol: RolResponse;
    fechaCreacion?: string;
    fechaActualizacion?: string;
    creadoPor?: number;
    actualizadoPor?: number;
};

/**
 * Estado operativo de parqueaderos y vehículos. Es distinto de `EstadoUsuario`:
 * estas dos entidades no tienen `INICIAL`, así que el tipo no se reutiliza.
 */
export type EstadoOperativo = 'ACTIVO' | 'INACTIVO';

/**
 * Esquema `ParqueaderResponseCreate` del backend (el nombre va sin la "o", es un
 * typo del backend). Lo devuelven `GET /parqueaderos`, `POST /parqueaderos` y
 * `PUT /parqueaderos/{id}`. No incluye `estado`, aunque el `PUT` sí permita
 * cambiarlo.
 */
export type ParqueaderoResponse = {
    codParqueadero: number;
    nombre: string;
    callePrincipal: string;
    calleSecundaria?: string;
    latitud?: number;
    longitud?: number;
    urlDireccion?: string;
    estado: EstadoOperativo;
};

/**
 * Esquema `VehiculoResponseCreate` del backend. Lo devuelven los cuatro
 * endpoints de `registro_vehicular`. Es la única respuesta de la api que sí
 * trae el estado; el QR llega como base64.
 */
export type VehiculoResponse = {
    codVehiculo: number;
    placa: string;
    conductor: string;
    estado: EstadoOperativo;
    codParqueadero: number;
    qrCodeBase64: string;
};

/**
 * Tipo de un movimiento. Lo usan tanto `POST /movimientos` como los dos
 * reportes de `/movimientos/reporte/**`.
 */
export type TipoMovimiento = 'ENTRADA' | 'SALIDA';

/**
 * Esquema `MovimientoResponseReport` del backend. Lo devuelven
 * `GET /movimientos/reporte/todos` y `GET /movimientos/reporte/por-fechas`.
 * Llega aplanado: repite en cada fila los datos del usuario que registró, del
 * vehículo y del parqueadero, así que no hay que cruzarlo con otros listados.
 */
export type MovimientoReporteResponse = {
    codUsuarioRegistro: number;
    nombreUsuarioRegistro: string;
    latitudRegistro?: number;
    longitudRegistro?: number;
    fechaRegistro: string;
    tipoMovimiento: TipoMovimiento;
    codVehiculo: number;
    placa: string;
    conductor: string;
    codParqueadero: number;
    nombreParqueadero: string;
    callePrincipalParqueadero: string;
    calleSecundariaParqueadero?: string;
    latitudParqueadero?: number;
    longitudParqueadero?: number;
    urlDireccionParqueadero?: string;
};

/**
 * Estado que reporta el actuator de Spring Boot. `UNKNOWN` no lo manda el
 * backend: lo usa el front cuando la respuesta no se pudo leer (por ejemplo si
 * el servidor no está levantado y no hay cuerpo que interpretar).
 */
export type EstadoSalud = 'UP' | 'DOWN' | 'OUT_OF_SERVICE' | 'UNKNOWN';

/**
 * Respuesta de `GET /actuator/health`. Con el detalle desactivado llega solo
 * `{ groups, status }`; si el backend expone los detalles, cada componente
 * (base de datos, disco, ping) informa su propio estado en `components`.
 */
export type SaludResponse = {
    status: EstadoSalud;
    groups?: string[];
    components?: Record<string, { status: EstadoSalud }>;
};
