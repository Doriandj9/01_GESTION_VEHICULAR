# Memoria del proyecto (app móvil Flutter)

Decisiones tomadas. Se apuntan una vez y no se vuelve a discutir.

Alcance actual: **una sola app móvil** (no micro apps) con solo dos funcionalidades:
1. **Login** para usuarios con rol `GUARDIA`.
2. **Registrar movimientos** (`ENTRADA` / `SALIDA`) escaneando el QR del vehículo.

Todo lo demás del backend (usuarios, parqueaderos, registro vehicular, reportes) es de la web de
administración y **no se implementa aquí**.

# Decisiones de arquitectura

- Arquitectura por capas en `lib/`: `data`, `domain` (opcional) y `ui`, con MVVM. Se crea con la skill
  `create-functionality-flutter`.
- Dependencias entre capas: `ui` → `domain` (opcional) → `data`. La UI nunca llama al `ApiClient`
  directamente; siempre pasa por un repositorio.
- Lo compartido (temas, `Result`, `Command`, widgets globales) vive en `lib/core/`, no en un paquete
  aparte.
- Nomenclatura: archivos en `snake_case`, clases e interfaces (`abstract`) en `PascalCase`,
  propiedades, variables y métodos en `camelCase`. Código y comentarios en español.
- Todo repositorio tiene interfaz (`abstract`) e implementación (`_impl`), y la implementación se
  registra casteada a su interfaz.
- Todo resultado de red/acción se encapsula en `Result<T>` (`Ok` / `Error`) de
  `lib/core/utils/result.dart`. Los viewmodels devuelven el mismo `Result` que entrega el repositorio.
- Las acciones de la UI se encapsulan en `Command0<T>` / `Command1<T, A>`
  (`lib/core/utils/command.dart`). El widget que reacciona a un comando es `StatefulWidget` y hace
  `addListener` en `initState`, `remove` + `add` en `didUpdateWidget`, `removeListener` en `dispose`, y
  `clearResult()` solo cuando `completed` o `error`.
- **Nunca** se registran los viewmodels en `provider`: se crean en el `builder` de la ruta con
  `context.read()`. Sí se registran el `ApiClient`, los repositorios y los casos de uso, en orden, en
  `lib/config/dependencies.dart`.
- Los modelos (DTO de api y modelos de dominio) son inmutables: `final class`, campos `final`,
  constructor `const`, con `fromJson`, `toJson`, `copyWith`, `toString`, `==` y `hashCode`. El
  repositorio transforma el DTO al modelo de dominio; la UI no usa DTOs.
- El `ApiClient` (`data/services/api/api_client.dart`, paquete `http`) crea un cliente por petición y lo
  cierra en el `finally`. La url base viene de `Env`, nunca escrita a mano.
- Una sola app: un único `GoRouter` (`lib/routing/`) con rutas absolutas simples. No hay `MicroApp`, ni
  prefijos por ambiente, ni rutas de assets con `packages/<app>/`.
- Variables de entorno con `envied` desde `.env` en la raíz (`lib/config/env.dart`). `.env` y
  `env.g.dart` van en `.gitignore`. Tras cambiar el `.env`:
  `dart run build_runner clean` y `dart run build_runner build --delete-conflicting-outputs`.
- Colores institucionales en `lib/core/themes/colors.dart`, alimentando `AppTheme` (tema claro y
  oscuro). Se usan solo vía `Theme.of(context).colorScheme.*`, nunca con el hexadecimal escrito a mano:
  - `primario` = `#1A9A3E` (verde), con variante clara y oscura
  - `carbon` = `#2B2B2B` (negro carbón, no negro puro), con variante clara y oscura
- Medidas (paddings, márgenes) solo desde `Dimens.of(context)`.
- El nombre de la entidad nunca se escribe fijo en el código. Vive en el `.env` / `Env`:
  - `nombre` = "Gobierno Autónomo Descentralizado Municipal de La Joya de los Sachas"
  - `alias` = "GADMJS"
  Variables del `.env`: `ENTIDAD_NOMBRE` y `ENTIDAD_ALIAS`.
- El resultado de una acción (login, registrar movimiento) se informa con un diálogo/aviso global
  reutilizable en `lib/core/ui/widgets/`, no con uno distinto por pantalla. Aplica la regla de
  presentación de errores (sección "Errores de la api"). Será un diálogo global.
- Paquetes base: `provider go_router intl shared_preferences logging cached_network_image envied http`
  y de desarrollo `build_runner envied_generator mocktail`. Específicos del móvil: `mobile_scanner`,
  `geolocator` y `flutter_secure_storage`.

# Decisiones específicas del móvil (no están en la documentación)

- Escáner de QR: paquete `mobile_scanner`. Se pide permiso de cámara y el contenido leído se envía tal cual como `data`.
- Ubicación: paquete `geolocator` para obtener `latitud` y `longitud` al registrar
  el movimiento (campos opcionales en la api). Si el usuario niega el permiso, el movimiento se
  registra sin coordenadas.
- Almacenamiento de tokens: `flutter_secure_storage` en lugar de
  `shared_preferences`, porque el jwt y el refresh token son credenciales. `shared_preferences` queda
  para preferencias no sensibles.
- Si un usuario con rol `ADMINISTRADOR` inicia sesión en la app móvil: se rechaza
  con un mensaje ("Esta aplicación es solo para guardias"), se limpia la sesión y no se navega a
  ninguna pantalla.

# Contrato de la api (backend Spring Boot)

OpenAPI en `/v3/api-docs` (Swagger UI en `/swagger-ui/index.html`). Catálogo **revisado el
2026-10-19 contra `http://10.143.10.72:8080`** (servidor de la red local; antes se revisó en
`localhost:8080`). Prefijo `/api/v1.0` (se arma desde `Env`). Todas las rutas van **sin barra
final**. Seguridad: esquema `Bearer` (JWT), header `Authorization: Bearer <jwt>`.
**`POST /auth` es el único endpoint público**; todos los demás exigen jwt.

En un emulador de Android `localhost` apunta al propio emulador: para llegar al backend de la máquina
de desarrollo se usa `10.0.2.2` en el `.env`. En un dispositivo físico, la IP de la red local
(hoy `10.143.10.72`).

## Autenticación

- `POST /auth` (`login`) → `{ correo*, password* }` (`correo` con formato email). Responde
  `AuthResponse`: `{ jwt, refreshToken, jwtExpired }` (`jwtExpired` es `int64`: duración en ms, ~24 h).
  **No devuelve los datos del usuario**: para eso se llama a `GET /usuarios/detalle` con el jwt.
- `POST /auth/refresh` (`refresh`) → `{ token* }` responde el mismo `AuthResponse`.
- `POST /auth/logout` (`logout`) → `{ token* }` responde `{ state, message }`.
- `POST /auth/change-password` (`changePassword`) → `{ correo*, oldPassword*, newPassword* }`, los tres
  obligatorios. Responde un `AuthResponse` nuevo: hay que reemplazar los tokens guardados y volver a
  pedir `/usuarios/detalle`.

## Usuario de la sesión

- `GET /usuarios/detalle` (`detalle`) → sin cuerpo ni parámetros; devuelve el usuario dueño del jwt como
  `{ codUsuarios, nombres, correo, estado, rol }` (`rol` y `estado` llegan como texto plano). Es el
  flujo obligado después del login para conocer al usuario y su rol.

## Movimientos (lo único que registra la app)

- `POST /movimientos` (`registrar`) → `{ data*, tipo, latitud, longitud }`. `data` es el contenido
  escaneado del QR (texto, mínimo 1) y `tipo` es `ENTRADA` | `SALIDA`. Responde `MovimientoResponse`:
  `{ registro, estado }` con `registro` como `date-time` y `estado` = `SUCCESS` | `ERROR`.
  Ojo: **un movimiento rechazado puede llegar como 200 con `estado: 'ERROR'`**, no solo como error
  http, así que hay que revisar el campo antes de dar el registro por bueno. El repositorio debe
  convertir `ERROR` en `Result.error`.
- `GET /movimientos/usuario` (`listarPorUsuario`) — **nuevo el 2026-10-19**. Parámetros de consulta
  **obligatorios** `cod` (`int64`) y `fecha` (`date-time`). Responde un arreglo de
  `MovimientoResponseRegistrado`:
  `{ codUsuarioRegistro, nombreUsuarioRegistro, latitudRegistro, longitudRegistro, fechaRegistro,
  tipoMovimiento, codVehiculo, placa, conductor }`.
  Según la consulta del backend (`MovimientoRepository.findByFechaDesde`):
  - `cod` es el `codUsuarios` del usuario que **registró** el movimiento (`M.creadoPor`), no el del
    vehículo ni del conductor;
  - `fecha` es un **desde inclusive** (`M.fecha >= :fecha`), no un rango;
  - el resultado viene ordenado por `fecha` descendente.
  `fecha` viaja en el mismo formato que los reportes: `yyyy-MM-ddTHH:mm:ss` (sin zona).
  Es el único endpoint de lectura de movimientos que sirve a la app: con el `codUsuarios` del guardia
  autenticado permite mostrar "mis movimientos registrados" desde una fecha. No lleva datos de
  parqueadero (eso es `MovimientoResponseReport`, de la web).
  Ojo: el `cod` **no está limitado al usuario del jwt**, así que la api acepta consultar los
  movimientos de otro usuario. La app siempre debe mandar el `codUsuarios` de su propia sesión.

## Catálogo completo de endpoints (2026-10-19)

Lo que **usa la app móvil**: `POST /auth`, `POST /auth/refresh`, `POST /auth/logout`,
`POST /auth/change-password`, `GET /usuarios/detalle`, `POST /movimientos` y
`GET /movimientos/usuario`. El resto es de la web de administración y no se implementa aquí.

| Método | Ruta | operationId | Parámetros / cuerpo | Respuesta | Seguridad |
|---|---|---|---|---|---|
| POST | `/auth` | `login` | `AuthRequest` | `AuthResponse` | pública |
| POST | `/auth/refresh` | `refresh` | `AuthRefresh` | `AuthResponse` | Bearer |
| POST | `/auth/logout` | `logout` | `AuthRefresh` | `LogoutResponse` | Bearer |
| POST | `/auth/change-password` | `changePassword` | `AuthRequestChangePassword` | `AuthResponse` | Bearer |
| GET | `/usuarios/detalle` | `detalle` | cabecera `Authorization` | `UsuarioDetalle` | Bearer |
| GET | `/usuarios` | `listAll` | — | `UsuarioResponse[]` | Bearer + rol `ADMINISTRADOR` |
| POST | `/usuarios` | `register` | `UsuarioRequestCreate` | `UsuarioResponse` | Bearer + rol `ADMINISTRADOR` |
| PUT | `/usuarios/{id}` | `update` | `UsuarioRequestUpdate` | `Usuario` | Bearer + rol `ADMINISTRADOR` |
| POST | `/movimientos` | `registrar` | `MovimientoRequestCreate` | `MovimientoResponse` | Bearer |
| GET | `/movimientos/usuario` | `listarPorUsuario` | `cod*`, `fecha*` (query) | `MovimientoResponseRegistrado[]` | Bearer |
| GET | `/movimientos/reporte/todos` | `obtenerTodos` | `cantidad?` (query) | `MovimientoResponseReport[]` | Bearer |
| GET | `/movimientos/reporte/por-fechas` | `obtenerPorFechas` | `fechaInicial*`, `fechaFinal*` (query) | `MovimientoResponseReport[]` | Bearer |
| GET | `/parqueaderos` | `listar_1` | — | `ParqueaderResponseCreate[]` | Bearer |
| POST | `/parqueaderos` | `create_1` | `ParqueaderoRequestCreate` | `ParqueaderResponseCreate` | Bearer |
| PUT | `/parqueaderos/{id}` | `update_1` | `ParqueaderoRequestUpdate` | `ParqueaderResponseCreate` | Bearer |
| GET | `/registro_vehicular` | `listar` | — | `VehiculoResponseCreate[]` | **no declarada** |
| GET | `/registro_vehicular/{id}` | `listarVehiculoPorId` | `id` (path) | `VehiculoResponseCreate` | **no declarada** |
| POST | `/registro_vehicular` | `create` | `VehiculoRequestCreate` | `VehiculoResponseCreate` | Bearer |
| PUT | `/registro_vehicular/{id}` | `actualizar` | `VehiculoRequestUpdate` | `VehiculoResponseCreate` | Bearer |
| GET | `/info/media` | `info` | — | `string` | Bearer |
| GET | `/api/v2.0/info/media` | `infov2` | — | `string` | Bearer |

Las dos rutas `GET /registro_vehicular*` no declaran `security` en el OpenAPI, pero **sí exigen jwt**:
`SecurityConfig` solo deja público `POST /api/v1.0/auth/**`, y el resto cae en
`anyRequest().authenticated()`. Solo `/api/{version}/usuarios/**` pide rol `ADMINISTRADOR`, con la
excepción de `GET /usuarios/detalle`, que es `authenticated()`.

## Enumeraciones

- `rol` = `ADMINISTRADOR` | `GUARDIA`.
- `estado` de usuario = `ACTIVO` | `INACTIVO` | `INICIAL`.
- `tipo` de movimiento = `ENTRADA` | `SALIDA`.
- `estado` de la respuesta de un movimiento = `SUCCESS` | `ERROR`.

## Comportamiento real observado (no está en el OpenAPI)

- `POST /auth` con credenciales malas responde **401** con
  `{ timestamp, status, error, errors: {}, message }`.
- Un endpoint protegido sin jwt (o con jwt inválido) responde **403**, no 401, y ese cuerpo llega
  **sin `message` ni `errors`** (solo `timestamp`, `status`, `error`, `path`). Por eso se intenta
  renovar el token ante 401 **y** 403, y por eso el helper de errores necesita un mensaje de reserva.
- `POST /auth/refresh` con un refresh token inválido responde **500**, no 401. Por eso cualquier error
  del refresco marca la sesión como expirada.
- Hay endpoints que no declaran `security` en el OpenAPI pero sí exigen jwt. No hay que tratar como
  público nada que no sea `POST /auth`.

# Manejo de la sesión en el front

- El jwt y el refresh token se manejan **solo** a través de un `TokenStore`
  (`lib/data/...` o `lib/core/...`), nunca accediendo al almacenamiento directamente.
  Claves: `gv_jwt` y `gv_refresh_token`.
- El estado global de la sesión (usuario detalle, `sesionExpirada`) vive en un `SesionStore`
  (`ChangeNotifier`, provisto en `dependencies.dart`). `cerrarSesion()` limpia todo; `expirarSesion()`
  lo usa la capa de red.
- Como el paquete `http` no tiene interceptores, el `ApiClient` agrega `Authorization: Bearer <jwt>` a
  toda petición salvo `/auth` y `/auth/refresh`, y ante 401/403 renueva el token y reintenta la
  petición **una sola vez**. Los refrescos simultáneos comparten una única llamada. No reintenta
  `/auth/change-password` ni `/auth/logout`: ahí un 401 es error de negocio, no un jwt caducado.
- Flujo del login: `POST /auth` → guardar tokens → `GET /usuarios/detalle` → `SesionStore`.
- Navegación tras el login (redirect del `GoRouter` según `SesionStore`):
  estado `INICIAL` → `/cambiar-clave`; rol `GUARDIA` → `/movimientos`; cualquier otro rol → se rechaza.
- Al abrir la app, si hay un token guardado se restaura la sesión llamando a `/usuarios/detalle`; si
  falla, se vuelve al login.

# Errores de la api

Todos los endpoints devuelven el mismo formato: `{ timestamp, status, error, errors, message, path }`.

Reglas de presentación, obligatorias en toda la ui:
- **Siempre** se muestra el campo `message`.
- Si `errors` no es `{}`, se muestran además sus pares campo → mensaje dentro del mismo aviso (son
  validaciones, por ejemplo `{ "correo": "debe ser una dirección...", "password": "no debe estar vacío" }`).
- Un helper único (`lib/core/utils/api_errors.dart`) normaliza cualquier error de `http` a
  `{ message, errors }` y pone un mensaje genérico si la api no respondió el formato.
- Ese helper también traduce una excepción que no venga de http (por ejemplo una validación del front
  antes de llamar a la api) para que el aviso muestre ese texto en vez del genérico.
- Sin conexión o tiempo agotado: mensaje propio ("Sin conexión con el servidor"), no el genérico.

# Reglas de clave y cambio obligatorio

- Si `GET /usuarios/detalle` devuelve `estado: "INICIAL"`, el usuario **debe** cambiar su clave antes
  de usar la app. El redirect del router manda a `/cambiar-clave` mientras el estado sea `INICIAL` y
  impide entrar a esa pantalla a quien ya la cambió.
- Reglas de una clave nueva (`lib/domain/...reglas_clave.dart`): mínimo 8 caracteres, mayúscula,
  minúscula, número, carácter especial, sin espacios, y distinta de la clave actual.

# Comportamiento verificado del backend (probado de punta a punta el 2026-10-14)

- `POST /auth/change-password` **funciona**: devuelve jwt y refreshToken **nuevos** y deja al usuario en
  estado `ACTIVO`.
- `POST /auth/refresh` y `POST /auth/logout` respondían **500 siempre** (observado el 2026-10-14);
  el backend ya lo corrigió (2026-10-19). Si el refresco falla, la app marca la sesión como expirada.
  El logout llama a la api y, falle o no, limpia la sesión local.
- `jwtExpired` llega como duración en milisegundos (~86400000 = 24 h), no como epoch.
- Claims del jwt: `jti`, `sub` (correo), `iat`, `type` (`ACCESS_TOKEN` / `REFRESH_TOKEN`),
  `ident` (codUsuarios), `roles` (arreglo; vacío en el refresh token), `exp`.
- Las pruebas anteriores se hicieron con un usuario `ADMINISTRADOR`, y su clave dejó de servir al
  2026-10-16. Para probar la app móvil hace falta **un usuario con rol `GUARDIA`** y confirmar su clave
  vigente antes de probar la api.
# Lenguaje visual de la ui (tomado de `assets/img/mockup.png`, adaptado a móvil)

El mockup es la pantalla web de administración; la app móvil **no la copia**, copia su lenguaje
visual. Lo que se conserva y cómo se traduce a una pantalla de teléfono:

- **Barra superior carbón** (`AppColors.carbon` `#2B2B2B`) con texto blanco, sin elevación ni sombra,
  título alineado a la izquierda: "Gestión Vehicular" arriba y el alias de la entidad (`Env.entidadAlias`)
  debajo en menor tamaño. En móvil ocupa el `AppBar`, y la acción de salir va como `IconButton` o
  `TextButton` a la derecha (en el mockup es un botón con borde).
- **Acento verde** (`AppColors.primario` `#1A9A3E`): en el mockup aparece como una barra corta
  (`Dimens.anchoAcento` x `Dimens.altoAcento`) encima del título de cada tarjeta y como barra vertical
  junto al título de la cabecera. Esa barrita es el sello de la marca y se repite en móvil al
  encabezar cada tarjeta/sección.
- **Fondo gris muy claro** (`AppColors.fondoClaro` `#F7F8F7`) y **tarjetas blancas** con borde fino
  (`AppColors.borde` `#E4E7E4`, 1 px), esquinas de `Dimens.radioTarjeta` (12) y **sin sombra**
  (`elevation: 0`). El contraste lo da el borde, no la sombra.
- **Jerarquía de texto**: título de pantalla en `headlineMedium`/`headlineSmall` carbón, subtítulo de
  bienvenida en `bodyMedium` gris (`onSurfaceVariant` `#8A8F8A`), título de tarjeta en `titleSmall`
  carbón y descripción en `bodySmall` gris.
- **Tarjetas en columna** (una por fila) en lugar de la rejilla de 3 columnas del mockup; en tablet
  (`Dimens.tablet`) el contenido se limita a `anchoMaximoContenido`.
- **Botones**: acción principal `FilledButton` verde de ancho completo (`Dimens.altoBoton` = 48);
  acción secundaria (como "Salir") `OutlinedButton` con borde gris y texto carbón, nunca un segundo
  botón de color.
- El texto del rol se muestra en verde sobre la barra carbón, como en el mockup.

# Tema y medidas ya implementados

- `lib/core/themes/colors.dart`: paleta (`primario`/`primarioClaro`/`primarioOscuro`/`primarioSuave`,
  `carbon`/`carbonClaro`/`carbonOscuro`, neutros, `error`) y los dos `ColorScheme`. En el tema oscuro
  el primario es `primarioClaro` (`#4CC46B`) para que contraste sobre `#121212`.
- `lib/core/themes/theme.dart`: `AppTheme.lightTheme` / `darkTheme` construidos con un único método
  privado `_construir(ColorScheme)`, con `appBarTheme`, `cardTheme`, `inputDecorationTheme`,
  `filledButtonTheme`, `outlinedButtonTheme`, `dialogTheme` y `snackBarTheme` ya alineados al mockup.
  La ui no vuelve a definir estos estilos en cada widget.
- `lib/core/themes/dimens.dart`: escala de espacios (`espacioMinimo`…`espacioExtra`), radios,
  `altoBoton`, `altoCampo`, `tamanoVisorQr` y las variantes `mobile` / `tablet` vía `Dimens.of(context)`.

# Estado de la inicialización (2026-10-19)

- `.env` creado en la raíz con `API_BASE_URL=http://10.0.2.2:8080`, `API_PREFIX=/api/v1.0`,
  `ENTIDAD_NOMBRE` y `ENTIDAD_ALIAS`. Hay un `.env.example` versionado; el `.env` y
  `lib/config/env.g.dart` están en `.gitignore`.
- `lib/config/env.dart` (`Env`, `envied`) expone `apiBaseUrl`, `apiPrefix`, `entidadNombre`,
  `entidadAlias` y el getter `apiUrl` (base + prefijo). `env.g.dart` ya generado.
- `pubspec.yaml` ya incluye las dependencias del móvil: `mobile_scanner`, `geolocator` y
  `flutter_secure_storage`, además de las base.
- `lib/main.dart`: `AppGestionVehicular` con `MaterialApp`, tema claro/oscuro y
  `themeMode: ThemeMode.system`; su `home` es una pantalla provisional que se reemplaza por el
  `GoRouter` y los providers al crear las funcionalidades de login y movimientos.

# Estructura por funcionalidad (2026-10-19)

- Cada funcionalidad es una carpeta en `lib/` con **sus capas dentro**
  (`lib/inicio_sesion/{data,domain,ui}`), no capas en la raíz agrupando funcionalidades.
- Lo que usan dos o más funcionalidades vive fuera de ellas: `lib/data/services/api/api_client.dart`
  (cliente único), `lib/data/stores/token_store.dart`, `lib/domain/models/sesion/` (`UsuarioModel`,
  `RolUsuario`, `EstadoUsuario`) y `lib/domain/stores/sesion_store.dart`.
- Todas las rutas van en `lib/routing/` (`routes.dart`, `router.dart` y `widgets/` con las pantallas
  propias del router: carga y marcadores de posición).
- `AppRoutes.cargando` (`/`) es la ruta inicial: el `redirect` no decide nada mientras
  `SesionStore.cargando` sea `true` (restauración de la sesión guardada con `lazy: false`).
- El lint `prefer_initializing_formals` está desactivado en `analysis_options.yaml`: las clases
  reciben dependencias por parámetro nombrado público y las guardan en campos privados.
- En el éxito del login no se abre diálogo: el `redirect` del router es el aviso. El diálogo global
  se usa para los errores y para avisar que la sesión expiró.

# Lectura de la cabecera Authorization (revisado en el código del backend, 2026-10-19)

- `dart:io` (y por tanto `package:http`) escribe **siempre el nombre de la cabecera en minúscula**:
  en el cable sale `authorization: Bearer ...` aunque en el mapa de Dart se escriba `Authorization`.
  No se puede cambiar desde `package:http`, y HTTP/2 exige minúsculas de todos modos.
- Por eso el backend debe leer la cabecera de forma insensible a mayúsculas
  (`request.getHeader(HttpHeaders.AUTHORIZATION)` o `@RequestHeader(name = HttpHeaders.AUTHORIZATION)`),
  nunca con `headers.get("Authorization")` sobre un `@RequestHeader Map<String,String>`:
  esa búsqueda es sensible a mayúsculas y devuelve `null`. Era el NPE de `GET /usuarios/detalle`.
- Rutas en `SecurityConfig`: `POST /api/v1.0/auth/**` es `permitAll()` (el filtro solo valida la
  cabecera si viene). `/api/{version}/usuarios/**` exige rol `ADMINISTRADOR`, con una excepción
  añadida para `GET /usuarios/detalle`, que es `authenticated()` porque devuelve solo al dueño del
  token y la app móvil (`GUARDIA`) lo necesita tras el login.
- `/auth/refresh`: el servicio usa el **cuerpo** `{ token }`, y el filtro, si llega cabecera, exige
  que sea de tipo `REFRESH_TOKEN` (`isTokenTypeForRequest`). La app envía el refresh token en ambos
  sitios. Todo lo demás exige `ACCESS_TOKEN` en la cabecera.

# Cambio de clave en estado INICIAL (2026-10-19)

Se replican los criterios de la web de administración (`gestionvehicular_front`,
`auth/presentation/cambiar-clave.page.*` y `auth/domain/reglas-clave.ts`):

- Reglas de la clave nueva en `lib/cambiar_clave/domain/reglas_clave.dart`, calcadas de
  `reglas-clave.ts`: mínimo 8, mayúscula, minúscula, número, carácter especial, sin espacios, más
  "distinta de la actual" (que se evalúa en el viewmodel, como en la página del front).
  `evaluarClave`, `claveEsValida` y `fortalezaClave` (0 a 3). Si cambian allá, cambian aquí.
- La ui muestra las métricas en vivo, la barra de fortaleza de tres segmentos, el aviso
  "Las claves no coinciden." y mantiene el botón deshabilitado hasta que todo esté correcto.
- Tras un error de la api se vacían los tres campos, igual que la web.
- El `correo` no se pide: lo toma del `SesionStore`. El caso de uso valida en el front antes de
  llamar a la api (clave débil o igual a la actual no generan petición).
- `CambiarClaveUseCase`: `POST /auth/change-password` -> guardar los tokens **nuevos** ->
  `GET /usuarios/detalle` -> `SesionStore`. Si el detalle falla después de cambiar la clave, se
  limpian los tokens y se marca la sesión como expirada (la clave ya cambió: hay que volver a entrar).
- La salida de `/cambiar-clave` la decide el `redirect` del router según el estado del usuario; la
  pantalla solo ofrece "Cerrar sesión" como alternativa. El éxito no abre diálogo (el redirect es el
  aviso); el error sí, con el diálogo global.

# Revisión del OpenAPI del 2026-10-19 (contra `http://10.143.10.72:8080`)

Comparada con la captura anterior (21 operaciones frente a 20):

- **Nuevo endpoint**: `GET /api/v1.0/movimientos/usuario` (`listarPorUsuario`), con el schema nuevo
  `MovimientoResponseRegistrado`. Documentado en "Movimientos". Es el primero de lectura de
  movimientos que sirve a la app móvil.
- **Nuevo schema**: `MovimientoResponseRegistrado` (como `MovimientoResponseReport` pero **sin** los
  campos de parqueadero).
- `GET /usuarios/detalle` ahora declara el parámetro de cabecera `Authorization`: es el reflejo del
  arreglo del NPE (`@RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false)`), así que ese
  servidor ya corre la corrección. También corre la excepción de rol para `/usuarios/detalle`.
- No hubo ningún otro cambio: ni rutas eliminadas, ni schemas eliminados, ni cambios en los cuerpos,
  parámetros o seguridad de las demás operaciones.
- El nuevo endpoint está protegido (sin jwt responde **403**, igual que el resto) y, por las reglas de
  `SecurityConfig`, lo puede consultar cualquier usuario autenticado, incluido el rol `GUARDIA`.
- Pendiente de probar de punta a punta con un usuario `GUARDIA`: el formato exacto de `fecha` se
  documenta por analogía con los reportes (`yyyy-MM-ddTHH:mm:ss`), no se verificó con un token real.

# Listado de movimientos en la pantalla del guardia (2026-10-19)

- Debajo de las dos acciones va `ListaMovimientosWidget`: los movimientos que **registró el guardia
  de la sesión**, con `GET /movimientos/usuario`. Sirve de confirmación de que el registro quedó
  guardado, así que **reemplazó** a la tarjeta de "último registro" (`ultimo_movimiento_widget.dart`,
  eliminada) y al getter `ultimoMovimiento` del viewmodel: la lista cumple las dos funciones.
- Filtro de fecha: por defecto **hoy** a las 00:00. Se rotula **"Desde"** y no "Fecha" porque la api
  trata el parámetro como un desde inclusive (`M.fecha >= :fecha`): al elegir un día anterior también
  se ven los posteriores. `showDatePicker` no permite fechas futuras y hay un atajo "Hoy".
- El `codUsuarios` lo pone `ListarMisMovimientosUseCase` desde el `SesionStore`; la ui no puede
  elegirlo. Es deliberado: el parámetro `cod` de la api no está limitado al dueño del jwt.
- Tras un registro con éxito la lista se recarga; si el filtro estaba en otro día, vuelve a hoy para
  que el movimiento recién hecho se vea.
- Se muestran como máximo `ListaMovimientosWidget.maximoVisible` (10) y se indica el total. Es un
  listado de apoyo, no un reporte: los reportes son de la web de administración.
- El repositorio **descarta** (con un aviso en el log) los registros que llegan sin `fechaRegistro` o
  con un `tipoMovimiento` desconocido, en vez de tumbar toda la lista.
- El `ApiClient` ganó soporte para respuestas de **arreglo** (`_peticionAutenticadaLista` +
  `_interpretarLista`) y para **parámetros de consulta**; el reintento ante 401/403 se extrajo a
  `_respuestaAutenticada` para que lo compartan las respuestas de objeto y de lista.

# Registro de movimientos (2026-10-19)

- Funcionalidad en `lib/movimientos/` con sus capas dentro (`data`, `domain`, `ui`). Se eliminó
  `lib/routing/widgets/pantalla_pendiente.dart`: ya no hay rutas sin pantalla real.
- Permisos declarados: en `AndroidManifest.xml` `CAMERA`, `ACCESS_FINE_LOCATION` y
  `ACCESS_COARSE_LOCATION`, más `uses-feature` de cámara (autofocus `required=false`); en
  `Info.plist` `NSCameraUsageDescription` y `NSLocationWhenInUseUsageDescription`.
  No hace falta tocar Gradle: `mobile_scanner` pide `minSdk 23` / `compileSdk 36` y los valores por
  defecto de Flutter son 24 y 36.
- **Cuándo se pide cada permiso**: el de ubicación, al abrir la pantalla (`Command0 pedirUbicacion`
  se ejecuta en el constructor del viewmodel); el de cámara lo dispara `mobile_scanner` al arrancar
  la cámara, y si se niega llega como `MobileScannerException` con
  `MobileScannerErrorCode.permissionDenied`, que el escáner muestra con su propio aviso.
- **La ubicación es mejor esfuerzo y nunca bloquea el registro**: si el permiso está negado, negado
  para siempre o el gps está apagado, el movimiento se registra sin `latitud` ni `longitud` (son
  opcionales en la api) y la pantalla lo avisa antes de escanear, con un botón para volver a pedir el
  permiso o abrir los ajustes (`Geolocator.openAppSettings()`).
- `geolocator` se usa **solo** en `movimientos/data/services/ubicacion_service_impl.dart`, detrás de
  la interfaz `UbicacionService`. Igual que los repositorios, se registra casteado a su interfaz.
- El escáner (`EscanerQrScreen`) se abre con `Navigator.push` y **no** es una ruta de `go_router`,
  porque devuelve un valor (el texto del QR) a quien lo abrió. Lee solo `BarcodeFormat.qrCode` con
  `DetectionSpeed.noDuplicates` y tiene un seguro (`_yaLeido`) para no cerrar dos veces.
- El contenido del QR es un jwt que valida el backend: la app lo envía **tal cual** como `data`, sin
  interpretarlo; solo recorta espacios y rechaza el texto vacío.
- Las dos acciones son **tarjetas pulsables**, no botones de color, porque tienen el mismo peso y el
  lenguaje visual admite un solo botón verde por pantalla. El orden lo fija el uso: **salida arriba,
  entrada abajo**.
- A diferencia del login y del cambio de clave, aquí el **éxito sí abre el diálogo global** (no hay
  navegación que sirva de aviso) e indica la hora y si quedó sin ubicación. El error también.

# Formato de las fechas en los parámetros de consulta (verificado el 2026-10-19)

- Los endpoints con fecha (`GET /movimientos/usuario`, `GET /movimientos/reporte/por-fechas`) reciben
  `java.util.Date` en el controlador. El proyecto **no** tenía `@DateTimeFormat`, ni `addFormatters`
  en `WebConfig`, ni `spring.mvc.format.date`, así que Spring no tenía conversor `String -> Date` y
  caía en el constructor `new Date(String)`, que **no acepta ISO 8601**.
- Comprobado con `DefaultFormattingConversionService` (el mismo `mvcConversionService` de Spring MVC):
  `2026-10-19T00:00:00`, `2026-10-19T00:00:00.000Z` y `2026-10-19` **fallan**; solo pasaban formatos
  del estilo `2026/10/19`, `Oct 19, 2026` o `10/19/26`.
- Arreglado en el backend: los tres parámetros de fecha de `MovimientoController` llevan
  `@DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")` (constante `FORMATO_FECHA`). Comprobado que
  ese patrón parsea `2026-10-19T00:00:00` y `2026-10-19T08:15:30`; **no** acepta solo la fecha, así
  que el cliente debe enviar siempre la hora.
- Esto corrige la nota anterior, que daba por bueno `yyyy-MM-ddTHH:mm:ss` "porque es lo que lee el
  `LocalDateTime` del backend": el parámetro no es `LocalDateTime` sino `Date`, y sin la anotación
  no se leía. Afectaba también al reporte por fechas de la web de administración.
- La app ya envía ese formato (`MovimientoRepositoryImpl._fechaParaApi`), así que no hubo que cambiar
  nada en el móvil.
- Aparte: los parámetros tenían `@NotEmpty` sobre `Long` y `Date`, que es un constraint inválido para
  esos tipos (`HV000030`). No estallaba porque la clase no tiene `@Validated` y las validaciones de
  parámetros de método no se aplican, pero se quitaron para que no exploten si alguien la añade.

## Acceso biométrico (2026-10-20)

- Funcionalidad `lib/acceso_biometrico/`, con sus capas dentro: `data/` (servicio de `local_auth`,
  `sources/` con sqlite y el repositorio), `domain/` (`jwt_payload.dart`, el modelo de la credencial
  y el caso de uso) y `ui/widgets/`. El icono de la huella vive en el login, así que **no** tiene
  viewmodel propio: lo atiende `InicioSesionViewmodel`, que es el de esa pantalla.
- La caducidad del refresh token se lee del claim **`exp`**, no de `iat`. `iat` es el momento de
  emisión; `JwtService.buildToken` del backend pone los dos. El refresh token dura
  `application.security.jwt.refresh-token.expiration` = 604800000 ms = **7 días**.
- La firma del jwt **no** se verifica en el móvil (no tiene la clave): el payload se decodifica solo
  para saber el correo y la caducidad, y para no gastar una llamada a `/auth/refresh` condenada a
  fallar. Quien valida de verdad es el backend.
- La credencial se guarda en sqlite (`sqflite`, `gestionvehicular.db`, tabla `credencial_biometrica`,
  una sola fila con `id = 1`), con el refresh token en **base64**. Base64 no es cifrado: lo que
  protege el acceso es la biometría del dispositivo. El jwt de la sesión activa sigue en
  `flutter_secure_storage` a través del `TokenStore`, que no cambió.
- `AuthService.getTokens` llama a `revokedAllTokens(usuario)` en **cada** login, refresco y cambio de
  clave: solo el último refresh token sirve. Por eso la credencial se vuelve a guardar en los cuatro
  sitios donde el par cambia: `IniciarSesionUseCase`, `CambiarClaveUseCase`,
  `IniciarSesionBiometricaUseCase` y el refresco silencioso del `ApiClient`
  (`alRenovarTokens`, nuevo callback hermano de `alExpirarSesion`).
- Cerrar sesión **borra** la credencial (`CerrarSesionUseCase`, nuevo; el botón de salir ya no llama
  al `SesionStore` directo). Motivo: un teléfono de garita puede tener registradas las huellas de
  varios guardias, y si la credencial sobreviviera, el del turno siguiente podría reabrir la sesión
  del anterior con su propia huella. También se borra cuando el backend rechaza el refresco o cuando
  el rol no es `GUARDIA`.
- `AuthService.logout` del backend es un método vacío que devuelve `null`: no revoca nada. El cierre
  de sesión es efectivo solo en el cliente (y por el revocado del siguiente login).
- El icono solo se pinta si hay biometría utilizable **y** credencial vigente; debajo se muestra el
  correo al que se va a entrar. Se usa `biometricOnly: true`: se comprueba a la persona, no que el
  teléfono esté desbloqueado con pin.
- Android: `MainActivity` pasó a `FlutterFragmentActivity` (`local_auth` necesita una
  `FragmentActivity` para el `BiometricPrompt`) y se agregó `USE_BIOMETRIC`. iOS:
  `NSFaceIDUsageDescription`.

## Sondeo de salud al arrancar (2026-10-20)

- Funcionalidad `lib/salud_servidor/`: `data/models/salud_api_model.dart`,
  `data/repositories/salud_repository.dart` + impl, `domain/models/` (`estado_salud.dart`,
  `salud_servidor_model.dart`), `domain/stores/salud_store.dart` y
  `ui/widgets/sin_servidor_screen.dart`. Sin viewmodel: el estado lo lleva el store, porque el
  `redirect` del router también lo lee.
- `GET /actuator/health` responde `{"groups":["liveness","readiness"],"status":"UP"}`. Comprobado en
  vivo (200, sin token): en `SecurityConfig` `/actuator` y `/actuator/**` son `permitAll`, y el
  `application.yml` expone `openapi, swagger-ui, health, info`.
- Va **fuera** del prefijo de la api: `ApiClient.consultarSalud` usa `_uri.replace(path: '/actuator/health')`,
  así que no lleva `/api/v1.0` ni cabecera `Authorization`. Su tiempo máximo es de 8 s, no 20,
  porque bloquea el arranque.
- Un **503 con `{"status":"DOWN"}` no es un error de red**: el cuerpo se interpreta aunque el código
  no sea 2xx, porque ese estado es justo lo que hay que mostrar. Solo es `Result.error` lo que no se
  puede leer (servidor apagado, sin red, url mala, cuerpo sin `status`).
- Cualquier `status` no reconocido se trata como `UNKNOWN`, es decir, **no** se da por bueno.
- Orden de arranque: el `SaludStore` sondea primero y **solo si responde `UP`** dispara
  `SesionStore.restaurar()` (callback `alEstarDisponible`, asignado en `dependencies.dart`). Antes la
  restauración corría siempre; como `restaurar()` borra los tokens cuando falla
  `GET /usuarios/detalle`, un servidor apagado dejaba al guardia sin sesión guardada por un problema
  ajeno. Ya no.
- Ruta nueva `AppRoutes.sinServidor = '/sin-servidor'`. El `redirect` evalúa el servidor **antes** que
  la sesión, y `crearRouter` recibe los dos stores con
  `refreshListenable: Listenable.merge([saludStore, sesionStore])`.
- La pantalla muestra el mensaje, una tarjeta de detalles (url sondeada, estado recibido, grupos o el
  error de red) y un botón "Reintentar" que vuelve a sondear; si sale `UP`, la app continúa sola.
