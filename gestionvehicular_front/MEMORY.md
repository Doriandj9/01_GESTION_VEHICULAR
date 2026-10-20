# Memoria del proyecto

Decisiones tomadas. Se apuntan una vez y no se vuelve a discutir

- Utilizar `Interface` para contratos de tipo clases
- Utilizar `Type` para describir funciones, objetos y atributos de clase
- El equivalente al `.env` es `src/environments/`: `environment.ts` (desarrollo) y
  `environment.production.ts` (producción), intercambiados por `fileReplacements`
  en la configuración `production` de `angular.json`. El contrato vive en
  `environment.model.ts` (`Entorno`, `ConfiguracionApi`) y siempre se importa
  desde `src/environments` (nunca el archivo de producción directamente).
- Colores principales (institucionales) definidos como tema global de Tailwind v4 en
  `src/styles.css` dentro de `@theme`. Se usan solo con utilidades de Tailwind,
  nunca con el hexadecimal escrito a mano:
  - `primario` = `#1A9A3E` (verde), con `primario-claro` y `primario-oscuro`
  - `carbon` = `#2B2B2B` (negro carbón, no negro puro), con `carbon-claro` y `carbon-oscuro`
  Ejemplos: `bg-primario`, `text-carbon`, `border-carbon/15`, `hover:bg-primario-oscuro`.
- El resultado de cualquier acción (registrar, actualizar) se informa con el diálogo global
  `DialogoResultadoComponent` (`src/app/base/components/dialogo-resultado/`), montado una sola vez
  en `app.html`. Las pantallas no lo instancian: inyectan `DialogoResultadoService` y llaman a
  `exito(mensaje, titulo)` o `error(aErrorApi(fallo), titulo)`. El diálogo ya aplica la regla de
  presentación de errores: `message` siempre visible y `errors` como lista de campo → mensaje.
- El listado de usuarios se carga con `GET /usuarios` y se guarda en `UsuariosStore`
  (`src/app/usuarios/domain/usuarios.store.ts`). Tras registrar o actualizar no se vuelve a pedir el
  listado: el store se mantiene al día con `agregar()` y `reemplazar()`.
- Cuando un campo del formulario alimenta un `computed` (por ejemplo para habilitar el botón de
  enviar), el campo **debe** ser un `signal` y enlazarse con `[ngModel]="campo()"` +
  `(ngModelChange)="campo.set($event)"`. Con una propiedad plana el `computed` se calcula una sola
  vez y nunca se recalcula, así que el botón queda deshabilitado para siempre.
- Cada funcionalidad nombra su `NgModule` de datos con su propio prefijo (`UsuariosDataModule`,
  `ParqueaderosDataModule`, `RegistroVehicularDataModule`) para que puedan convivir varios en
  `importProvidersFrom` de `app.config.ts`.
- Una funcionalidad puede reutilizar el `Domain` de otra desde su capa `Presentation`: la página de
  registro vehicular inyecta `ListarParqueaderosUseCase` y `ParqueaderosStore` para poblar el
  selector de parqueadero y mostrar su nombre. Lo que sigue prohibido es que un `Domain` importe de
  un `Data` o de un `Presentation`, propio o ajeno.
- Cuando el `PUT` no devuelve un campo que sí acepta en el cuerpo, el repositorio conserva en el
  modelo el valor que acaba de enviar: es el único dato fiable que queda de ese campo. **El caso que
  motivó la regla (el `estado` de usuarios y de parqueaderos) ya no aplica**: desde el 2026-10-19
  `UsuarioResponse` y `ParqueaderResponseCreate` devuelven `estado`, así que el `estado: … | null` de
  los modelos `Usuario` y `Parqueadero`, el `estadoDesconocido()` y el distintivo "sin dato" de las
  dos pantallas quedaron obsoletos y hay que simplificarlos. La regla sigue vigente como principio.
- Al arrancar, la aplicación verifica `GET /actuator/health` con `provideAppInitializer`. **No se
  devuelve el observable** a propósito: si se bloqueara el arranque, un backend lento o colgado
  dejaría la pantalla en blanco. El resultado vive en `EstadoServidorStore` y el componente global
  `EstadoServidorComponent` (montado en `app.html` junto al diálogo) tapa la pantalla con el motivo
  cuando el estado no es `UP`.
- El repositorio de salud **nunca falla**: traduce el error http a un `SaludServidor` con estado
  `UNKNOWN` y el motivo en `detalle`. Un servidor caído no es una excepción que haya que manejar en la
  ui, es el resultado que la ui tiene que mostrar. `UNKNOWN` no lo manda el backend, lo pone el front.
- **El backend no manda cabeceras CORS en `/actuator/**`** (verificado el 2026-10-20: `/api/**`
  responde `Access-Control-Allow-Origin: http://localhost:4200`, `/actuator/health` no responde
  ninguna). Por eso `environment.api.urlSalud` es **relativa** en desarrollo (`/actuator/health`) y el
  dev-server la redirige con `proxy.conf.json`. En producción es absoluta, así que el backend tendrá
  que incluir `/actuator/**` en su configuración de CORS o el chequeo dará un falso negativo.
- La url del chequeo va en `environment.api.urlSalud` como url completa, no compuesta con
  `url` + `version`: el actuator cuelga de la raíz del servidor, fuera del prefijo de versión.
- Un `input[type=number]` con `ngModel` emite por `ngModelChange` un `number` (o `null` si lo escrito
  no es válido), **no el texto** del campo. Si la señal es de texto hay que pasar por un método que
  convierta (`actualizarCantidad`) y los conversores tipo `aNumero` reciben `unknown`, no `string`:
  llamar a `.trim()` sobre un número lanza una excepción sincrónica dentro del handler del submit, la
  señal `cargando` se queda en `true` y, como el botón es `[disabled]="… || cargando()"`, **queda
  deshabilitado para siempre**. Pasó en reportes (`cantidad`) y en parqueaderos (`latitud`/`longitud`).
- Todo handler que ponga `cargando` en `true` antes de armar la petición debe soltarla también si
  armarla falla (un `try/catch` alrededor, como en `ReportesPage.consultar`). Si no, cualquier
  excepción deja la pantalla trabada sin ningún mensaje visible.
- Los filtros que la api no soporta se resuelven en el cliente y viven en el `Store` de la
  funcionalidad, no en el componente: `ReportesStore` guarda el reporte crudo en `movimientos` y
  expone `movimientosFiltrados` como `computed` sobre la señal `filtroTipo`. Así cambiar entre
  `ENTRADA` y `SALIDA` no vuelve a llamar a la api (ninguno de los dos reportes acepta
  `tipoMovimiento` como parámetro) y la pantalla queda sin lógica de filtrado.
- `aErrorApi` también traduce un `Error` que no venga de http: es el caso de una validación que el
  front levanta antes de llamar a la api (el rango de fechas al revés en reportes). Así un caso de uso
  puede rechazar con `throwError(() => new Error('…'))` y el diálogo global muestra ese texto en vez
  del mensaje genérico.
- El QR del vehículo llega como base64 sin prefijo. El modelo `Vehiculo` expone `qrComoImagen()`, que
  arma el `data:image/png;base64,…` para el `src` de la imagen y tolera que la api algún día ya
  incluya el prefijo.
- El estado global de la sesión vive en `SesionStore` (`src/app/auth/domain/sesion.store.ts`),
  implementado con `signal`/`computed` y `providedIn: 'root'`.
- El nombre de la entidad nunca se escribe fijo en el código. Vive en las variables de
  ambiente como `environment.entidad` (contrato `DatosEntidad` en `environment.model.ts`):
  - `nombre` = "Gobierno Autónomo Descentralizado Municipal de La Joya de los Sachas"
  - `alias` = "GADMJS"
  En plantillas se expone desde el componente (`protected readonly entidad = environment.entidad`)
  y se usa como `{{ entidad.nombre }}` o `{{ entidad.alias }}`.

# Contrato de la api (backend Spring Boot)

OpenAPI en `http://localhost:8080/v3/api-docs` (Swagger UI en `/swagger-ui/index.html`).
Catálogo verificado el 2026-10-19. Prefijo `/api/v1.0` (ya está en `environment.api.version`);
existe `/api/v2.0` solo para `info/media`. Todas las rutas van **sin barra final**.
Seguridad: esquema `Bearer` (`http`/`bearerFormat: JWT`, header `Authorization: Bearer <jwt>`).
**`POST /auth` es el único endpoint público**; todos los demás exigen jwt (ver la nota de los
endpoints que no declaran `security` más abajo).

## Autenticación

- `POST /auth` (`login`) → `{ correo*, password* }` (`correo` con formato email) responde
  `AuthResponse`: `{ jwt, refreshToken, jwtExpired }` (`jwtExpired` es `int64`: duración en ms, ~24 h).
  **No devuelve los datos del usuario**: para eso se llama a `GET /usuarios/detalle` con el jwt.
- `POST /auth/refresh` (`refresh`) → `{ token* }` responde el mismo `AuthResponse`.
- `POST /auth/logout` (`logout`) → `{ token* }` responde `{ state, message }`.
- `POST /auth/change-password` (`changePassword`) → `{ correo*, oldPassword*, newPassword* }`, los tres
  obligatorios. Responde un `AuthResponse` nuevo, así que hay que reemplazar los tokens guardados y
  volver a pedir `/usuarios/detalle`.

## Usuarios

- `GET /usuarios/detalle` (`detalle`) → sin cuerpo ni parámetros; devuelve el usuario dueño del jwt como
  `{ codUsuarios, nombres, correo, estado, rol }` (`rol` y `estado` llegan como texto plano, sin enum
  en el schema). Es el flujo obligado después del login para conocer al usuario.
- `GET /usuarios` (`listAll`) → sin parámetros; responde un arreglo de `UsuarioResponse`. Sin paginación
  ni filtros.
- `POST /usuarios` (`register`) → `{ nombre*, correo*, rol* }` responde el mismo `UsuarioResponse` del
  listado. Ojo: la petición usa `nombre` singular y la respuesta `nombres`.
- `PUT /usuarios/{id}` (`update`) → `{ nombres, correo, password, rol, estado }` (todos opcionales)
  responde la entidad `Usuario` completa (`codUsuarios`, `estado`, auditoría `fechaCreacion`/
  `fechaActualizacion`/`creadoPor`/`actualizadoPor` como `int64`, `rol` como objeto `{ codRol, rol }`).
- `UsuarioResponse` = `{ codUsuario, nombres, correo, estado, rol }`. **Desde el 2026-10-19 sí incluye
  `estado` y `rol` con su enum** (antes solo traía `codUsuario`, `nombres`, `correo` y `rol`), así que
  el estado del listado ya no es desconocido y el "sin dato" de la ui quedó obsoleto.

## Parqueaderos

- `GET /parqueaderos` (`listar_1`) → sin parámetros; responde un arreglo de
  `ParqueaderResponseCreate` (sí, el schema del backend se llama así, sin la "o").
- `POST /parqueaderos` (`create_1`) → `{ nombre*, callePrincipal*, calleSecundaria, latitud, longitud,
  urlDireccion }` responde lo mismo más `codParqueadero` y `estado`.
- `PUT /parqueaderos/{id}` (`update_1`) → el cuerpo de creación con todos los campos opcionales **más
  `estado`** (`ACTIVO` | `INACTIVO`); responde `ParqueaderResponseCreate`.
- `ParqueaderResponseCreate` = `{ codParqueadero, nombre, callePrincipal, calleSecundaria, latitud,
  longitud, urlDireccion, estado }`. **Desde el 2026-10-19 sí incluye `estado`**, así que el desfase
  que obligaba a mostrar "sin dato" en parqueaderos desapareció.

## Registro vehicular

- `GET /registro_vehicular` (`listar`) → responde un arreglo de `VehiculoResponseCreate`.
- `GET /registro_vehicular/{id}` (`listarVehiculoPorId`) → responde un `VehiculoResponseCreate`.
- `POST /registro_vehicular` (`create`) → `{ placa*, conductor*, codParqueadero* }` (`codParqueadero`
  con mínimo 1) responde `VehiculoResponseCreate`.
- `PUT /registro_vehicular/{id}` (`actualizar`) →
  `{ placa, conductor, estado, codParqueadero }` (todos opcionales) responde `VehiculoResponseCreate`.
- `VehiculoResponseCreate` = `{ codVehiculo, placa, conductor, estado, codParqueadero, qrCodeBase64 }`
  (el QR llega en base64, sin el prefijo `data:`).

## Movimientos (controlador nuevo, agregado el 2026-10-19)

Es el módulo que consume el rol `GUARDIA` escaneando el QR del vehículo, más los reportes del
administrador. Todavía no tiene funcionalidad en el front.

- `POST /movimientos` (`registrar`) → `{ data*, tipo, latitud, longitud }`. `data` es el contenido
  escaneado del QR (texto, mínimo 1) y `tipo` es `ENTRADA` | `SALIDA`. Responde `MovimientoResponse`:
  `{ registro, estado }` con `registro` como `date-time` y `estado` = `SUCCESS` | `ERROR`.
  Ojo: **un movimiento rechazado puede llegar como 200 con `estado: 'ERROR'`**, no solo como error
  http, así que hay que revisar el campo antes de dar el registro por bueno.
- `GET /movimientos/reporte/todos` (`obtenerTodos`) → parámetro de consulta opcional `cantidad`
  (`int32`, los últimos N movimientos); responde un arreglo de `MovimientoResponseReport`.
- `GET /movimientos/reporte/por-fechas` (`obtenerPorFechas`) → parámetros de consulta **obligatorios**
  `fechaInicial` y `fechaFinal`, los dos `date-time` (iso 8601); responde un arreglo de
  `MovimientoResponseReport`.
- `MovimientoResponseReport` viene aplanado, sin objetos anidados, y repite los datos de las tres
  entidades: `{ codUsuarioRegistro, nombreUsuarioRegistro, latitudRegistro, longitudRegistro,
  fechaRegistro, tipoMovimiento, codVehiculo, placa, conductor, codParqueadero, nombreParqueadero,
  callePrincipalParqueadero, calleSecundariaParqueadero, latitudParqueadero, longitudParqueadero,
  urlDireccionParqueadero }`. No hay que cruzar nada contra los otros listados para armar el reporte.

## Varios

- `GET /info/media` (`info` en v1.0, `infov2` en v2.0) responde un `string`.
- `GET /actuator/health` (**no figura en el OpenAPI**, cuelga de la raíz y no del prefijo de versión)
  responde `{ groups: ['liveness','readiness'], status: 'UP' }`. Es **público**: no exige jwt
  (verificado el 2026-10-20). Con algún componente caído el actuator responde **503** con el mismo
  cuerpo y `status: 'DOWN'`, y si el detalle está habilitado agrega `components`. No manda cabeceras
  CORS: ver la nota del proxy en las decisiones.

## Enumeraciones

- `rol` = `ADMINISTRADOR` | `GUARDIA` (en todos los esquemas menos `UsuarioDetalle`, donde es `string`).
- `estado` de usuario = `ACTIVO` | `INACTIVO` | `INICIAL`.
- `estado` de parqueadero y de vehículo = `ACTIVO` | `INACTIVO` (**no tienen `INICIAL`**), así que no
  se puede reutilizar `EstadoUsuario` para ellos.
- `tipo` de movimiento = `ENTRADA` | `SALIDA`.
- `estado` de la respuesta de un movimiento = `SUCCESS` | `ERROR`.

Los tipos de las respuestas compartidas de la api viven en `src/app/base/apiTypes.ts`
(`UsuarioDetalleResponse`, `UsuarioCreadoResponse`, `UsuarioResponse`, `RolResponse`, `RolUsuario`,
`EstadoUsuario`, `EstadoOperativo`, `ParqueaderoResponse`, `VehiculoResponse`, `AuthTokensResponse`,
`LogoutResponse`, `ErrorRestGlobalResponse`) y se importan desde cualquier capa.

Pendientes del backend al 2026-10-19: siguen faltando el detalle de un usuario y de un parqueadero por
id, cualquier borrado, y paginación o filtros en los listados (el único acotador es `cantidad` en el
reporte de movimientos). Tampoco hay un endpoint que valide el QR sin registrar el movimiento.

Comportamiento real observado (no está en el OpenAPI):
- `POST /auth` con credenciales malas responde **401** con
  `{ timestamp, status, error, errors: {}, message }`.
- Un endpoint protegido sin jwt (o con jwt inválido) responde **403**, no 401, y ese cuerpo llega
  **sin `message` ni `errors`** (solo `timestamp`, `status`, `error`, `path`). Por eso el interceptor
  intenta renovar el token ante 401 **y** 403, y por eso `aErrorApi` necesita el mensaje de reserva.
- `POST /auth/refresh` con un refresh token inválido responde **500**, no 401.
  Por eso cualquier error del refresco marca la sesión como expirada.
- **Hay endpoints que no declaran `security` en el OpenAPI pero sí exigen jwt**: los dos `GET` de
  `registro_vehicular` (probado el 2026-10-16: sin token responden 403) y, desde el 2026-10-19,
  `GET /movimientos/reporte/por-fechas`. No hay que tratarlos como públicos ni excluirlos del
  interceptor: el único endpoint realmente público es `POST /auth`.

# Manejo de la sesión en el front

- `jwt` → `sessionStorage` (clave `gv_jwt`); `refreshToken` → `localStorage`
  (clave `gv_refresh_token`). Ambos se manejan solo a través de `TokenStore`
  (`src/app/auth/domain/token.store.ts`), nunca accediendo al almacenamiento directamente.
- `SesionStore` guarda el `UsuarioDetalle` y expone `sesionExpirada` para que la ui avise
  "vuelva a iniciar sesión". `cerrarSesion()` limpia todo; `expirarSesion()` lo usa el interceptor.
- `authInterceptor` (`src/app/auth/data/auth.interceptor.ts`, registrado en `app.config.ts` con
  `withInterceptors`) agrega `Authorization: Bearer <jwt>`, excluye `/auth` y `/auth/refresh`,
  y ante 401/403 renueva el token y reintenta la petición **una sola vez**. Los refrescos
  simultáneos comparten una única llamada (`TokenStore.refrescoEnCurso`).
- Flujo del login: `POST /auth` → guardar tokens → `GET /usuarios/detalle` → `SesionStore`.
- El `DataModule` de cada funcionalidad se registra en el injector **raíz**
  (`app.config.ts` con `importProvidersFrom`), no en los `providers` de la ruta ni del
  componente. Motivo: los casos de uso y los stores son `providedIn: 'root'`, y el
  interceptor también vive en la raíz; si el repositorio se provee más abajo, el injector
  raíz no lo encuentra y falla con `NG0201: No provider found for <X>Repository`.

# Errores de la api

Todos los endpoints devuelven el mismo formato (`ErrorRestGlobalResponse` del backend), tipado en
`src/app/base/apiTypes.ts`:
`{ timestamp, status, error, errors, message, path }`.

Reglas de presentación, obligatorias en toda la ui:
- **Siempre** se muestra el campo `message`.
- Si `errors` no es `{}`, se muestran además sus pares campo → mensaje dentro de la misma alerta
  (son validaciones, por ejemplo `{ "correo": "debe ser una dirección...", "password": "no debe estar vacío" }`).
- El helper `aErrorApi(fallo)` de `src/app/base/apiErrors.ts` normaliza cualquier error de
  `HttpClient` a `{ message, errors }` y pone un mensaje genérico si la api no respondió el formato.
  Se acompaña de `erroresDeValidacion()` y `tieneValidaciones()`.

Observado: algunas respuestas de error llegan sin `message` ni `errors` (p. ej. un 404 de
Spring), por eso el helper siempre debe tener mensaje de reserva.

# Reglas de clave y cambio obligatorio

- Si `GET /usuarios/detalle` devuelve `estado: "INICIAL"`, el usuario **debe** cambiar su clave
  antes de usar el sistema. Lo fuerzan los guards de `src/app/auth/presentation/guards/auth.guards.ts`:
  `sesionGuard` redirige a `/cambiar-clave` mientras el estado sea INICIAL y `claveInicialGuard`
  impide entrar a esa pantalla a quien ya cambió la clave.
- Las métricas de una clave nueva viven en `src/app/auth/domain/reglas-clave.ts`
  (`evaluarClave`, `claveEsValida`, `fortalezaClave`): mínimo 8 caracteres, mayúscula, minúscula,
  número, carácter especial, sin espacios, y distinta de la clave actual.
- `authInterceptor` **no reintenta** `/auth/change-password` ni `/auth/logout`: ahí un 401 es error
  de negocio (clave actual incorrecta), no un jwt caducado.
- Navegación tras el login: estado `INICIAL` → `/cambiar-clave`; rol `ADMINISTRADOR` → `/dashboard`;
  los demás roles todavía no tienen pantalla.

# Comportamiento verificado del backend (probado de punta a punta el 2026-10-14)

- Todas las rutas van **sin barra final**: `POST /api/v1.0/auth` es la correcta y `/auth/` da 404.
  (Se normalizó en el backend el 2026-10-14; antes era al revés, solo el login aceptaba la barra.)
- `POST /auth/change-password` **funciona**: devuelve jwt y refreshToken **nuevos** (distintos a los
  del login) y deja al usuario en estado `ACTIVO`. Hay que reemplazar los tokens guardados y volver
  a pedir `/usuarios/detalle`, que es justo lo que hace `ChangePasswordUseCase`.
- `POST /auth/refresh` y `POST /auth/logout` siguen respondiendo **500 siempre**, incluso con un
  refreshToken recién emitido y válido. Mientras no se corrijan: el refresco automático del
  interceptor no puede completarse (el front degrada con el aviso de sesión expirada) y el logout
  solo limpia la sesión local, que es lo que ya hace `LogoutUseCase`.
- `jwtExpired` llega como duración en milisegundos (~86400000 = 24 h), no como epoch.
- Claims del jwt: `jti`, `sub` (correo), `iat`, `type` (`ACCESS_TOKEN` / `REFRESH_TOKEN`),
  `ident` (codUsuarios), `roles` (arreglo; vacío en el refresh token), `exp`.
- Usuario de pruebas: `admin@gadmjs.com`, rol `ADMINISTRADOR`. Su clave se cambió el 2026-10-14 a
  `Gadmjs.2026*` al probar el flujo, y su estado pasó de `INICIAL` a `ACTIVO`. **Al 2026-10-16 esa
  clave ya no sirve** (el login responde 401, igual que con la original `12345`): la base se
  reinicializó o se cambió por fuera, así que antes de probar la api hay que confirmar la clave
  vigente.

Nota: `curl` desde el shell de esta sesión no alcanza `localhost`; para probar la api hay que usar
PowerShell con `Invoke-RestMethod`.
