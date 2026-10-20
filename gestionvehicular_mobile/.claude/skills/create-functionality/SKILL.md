---
name: create-functionality
description: Crear una funcionalidad completa en la app móvil Flutter de Gestión Vehicular (guardias) distribuida por capas (Data, Domain opcional, UI con MVVM). Úsala cuando se pida crear, agregar o estructurar una pantalla, módulo o funcionalidad nueva dentro de lib/ (por ejemplo "crea la funcionalidad de movimientos", "agrega la pantalla de login", "necesito la pantalla de cambiar clave").
---

# Crear una funcionalidad (app móvil Flutter)

Genera una funcionalidad completa por capas dentro de `lib/`: `data` (acceso a
apis), `domain` (modelos de negocio y casos de uso, **opcional**) y `ui`
(viewmodels y vistas). Arquitectura MVVM con `provider` y `go_router`. El código
y los comentarios van **en español**, las clases en `PascalCase`, los archivos en
`snake_case` y las propiedades, variables y métodos en `camelCase`.

Es **una sola app móvil** (no micro apps): no existen `MicroApp`, `entryPath`,
prefijos de ruta por ambiente ni assets con `packages/<app>/`. Hoy tiene dos
funcionalidades: login (rol `GUARDIA`) y registro de movimientos. Lo demás del
backend es de la web de administración y no se implementa aquí.

## Antes de escribir código

1. Lee `AGENTS.md` y `MEMORY.md` en la raíz del proyecto. Son obligatorios: ahí
   están las convenciones, el contrato de la api y las decisiones ya tomadas (no
   se vuelven a discutir).
2. Revisa `lib/core/` y reutiliza en lugar de redefinir: `themes/` (theme,
   colors, dimens), `utils/result.dart`, `utils/command.dart`,
   `utils/api_errors.dart`, `ui/widgets/` (incluido el diálogo global de
   resultados). Si `Result` o `Command` aún no existen, créalos primero (ver
   "Utilidades base").
3. Revisa `lib/config/dependencies.dart`, `lib/config/env.dart` y `lib/routing/`
   para integrarte a lo existente.
4. Confirma el nombre de la funcionalidad con el usuario solo si es ambiguo; si
   es claro, continúa.

## Estructura a crear

Las capas viven en la raíz de `lib/` y cada una agrupa por funcionalidad:

```
lib/
├── core/                              (compartido: themes, utils, widgets globales)
├── config/
│   ├── dependencies.dart              (providers de clientes, repos y use cases)
│   └── env.dart                       (variables de entorno con envied)
├── routing/
│   ├── app_routes.dart                (constantes de rutas)
│   └── app_router.dart                (GoRouter único)
├── data/
│   ├── services/api/
│   │   ├── api_client.dart            (un solo cliente; se agregan métodos)
│   │   └── models/<nombre>_api_model.dart
│   └── repositories/<funcionalidad>/
│       ├── <funcionalidad>_repository.dart        (interfaz abstract)
│       └── <funcionalidad>_repository_impl.dart   (implementación)
├── domain/                            (OPCIONAL)
│   ├── models/<funcionalidad>/<nombre>_model.dart
│   └── use_cases/<accion>_<funcionalidad>_use_case.dart
└── ui/<funcionalidad>/
    ├── viewmodels/<funcionalidad>_viewmodel.dart
    └── widgets/
        ├── <funcionalidad>_screen.dart  (punto de entrada de la vista)
        └── <componente>_widget.dart     (solo si se descompone la pantalla)
```

Reglas de dependencia: `ui` -> `domain` (opcional) -> `data`. La UI nunca llama a
`ApiClient` directamente; siempre pasa por un repositorio. Los modelos de
`data/services/api/models` no se usan en la UI: el repositorio los transforma.

## Utilidades base (solo si no existen)

**`Result<T>`** (`lib/core/utils/result.dart`): clase `sealed` con subclases `Ok`
y `Error` y factories `Result.ok(value)` / `Result.error(Exception)`. Se evalúa
con `switch`/`case Ok()` / `case Error()`.

**`Command`** (`lib/core/utils/command.dart`): encapsula una acción y expone
`running`, `completed`, `error`, `result` y `clearResult()`; se ejecuta con
`execute()`. Existen `Command0<T>` (sin parámetros) y `Command1<T, A>` (un
parámetro; para varios valores usa un record, ej. `(String, String)`). No guarda
estado de negocio: solo informa si la acción corre, falló o terminó.

**Errores de la api** (`lib/core/utils/api_errors.dart`): helper único que
normaliza cualquier error de `http` a `{ message, errors }`, con mensaje de
reserva si la api no respondió el formato, y que también traduce excepciones que
no vienen de http y la falta de conexión.

## Capa Data

### 1. Modelo de API (DTO)

`data/services/api/models/<nombre>_api_model.dart`. Castea la respuesta cruda de
los endpoints. Es **inmutable** (`final class`, campos `final`, constructor
`const`) y debe tener: `fromJson`, `toJson`, `copyWith`, y sobrescribir
`toString`, `operator ==` y `hashCode`.

```dart
final class MovimientoApiModel {
  final String registro;
  final String estado;

  const MovimientoApiModel(this.registro, this.estado);

  factory MovimientoApiModel.fromJson(Map<String, dynamic> json) {
    return MovimientoApiModel(
      json['registro'] as String,
      json['estado'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'registro': registro, 'estado': estado};

  MovimientoApiModel copyWith({String? registro, String? estado}) {
    return MovimientoApiModel(registro ?? this.registro, estado ?? this.estado);
  }

  @override
  String toString() => 'MovimientoApiModel(registro: $registro, estado: $estado)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovimientoApiModel &&
        other.registro == registro &&
        other.estado == estado;
  }

  @override
  int get hashCode => Object.hash(registro, estado);
}
```

### 2. ApiClient

`data/services/api/api_client.dart` (paquete `http`). Si ya existe, **agrega un
método** por endpoint; no crees otro cliente. Reglas:

- Recibe la `Uri` base (desde `Env`, nunca escrita a mano) y una `clientFactory`.
- **Cada petición crea un cliente nuevo y lo cierra en el `finally`.**
- Devuelve siempre `Result<T>`.
- Agrega `Authorization: Bearer <jwt>` a toda petición salvo `/auth` y
  `/auth/refresh`; ante 401/403 renueva el token y reintenta **una sola vez**
  (no reintenta `/auth/change-password` ni `/auth/logout`). Esa lógica ya vive en
  el cliente: no la dupliques por funcionalidad.

```dart
Future<Result<MovimientoApiModel>> registrarMovimiento(Map<String, dynamic> cuerpo) async {
  final client = _clientFactory();
  final url = _uri.replace(path: '/api/v1.0/movimientos');
  final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
  try {
    final response = await client.post(url, headers: headers, body: jsonEncode(cuerpo));
    _log.info('Respuesta de $url: ${response.statusCode}');
    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return Result.ok(MovimientoApiModel.fromJson(json));
    }
    return Result.error(_errorDeApi(response)); // usa api_errors.dart
  } on Exception catch (e) {
    return Result.error(e);
  } finally {
    client.close();
  }
}
```

### 3. Repositorio (interfaz + implementación)

Siempre **interfaz `abstract` y su implementación** para evitar acoplamiento. El
repositorio extrae datos del servicio y los transforma al modelo de dominio
(mapeo DTO -> modelo), y maneja caché, errores y reintentos si aplica. Respeta
las reglas del contrato de `MEMORY.md` (por ejemplo, un movimiento con
`estado: 'ERROR'` llega como 200 y el repositorio lo convierte en
`Result.error`).

```dart
abstract class MovimientoRepository {
  Future<Result<MovimientoModel>> registrar({
    required String data,
    required TipoMovimiento tipo,
    double? latitud,
    double? longitud,
  });
}

class MovimientoRepositoryImpl extends MovimientoRepository {
  MovimientoRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<MovimientoModel>> registrar({
    required String data,
    required TipoMovimiento tipo,
    double? latitud,
    double? longitud,
  }) async {
    final result = await _apiClient.registrarMovimiento({
      'data': data,
      'tipo': tipo.name.toUpperCase(),
      'latitud': latitud,
      'longitud': longitud,
    });
    switch (result) {
      case Error<MovimientoApiModel>():
        return Result.error(result.error);
      case Ok<MovimientoApiModel>():
    }
    // Un 200 con estado ERROR es un rechazo de negocio, no un éxito
    if (result.value.estado == 'ERROR') {
      return Result.error(Exception('El movimiento fue rechazado'));
    }
    // Se mapea el DTO de la api al modelo de dominio
    return Result.ok(MovimientoModel(DateTime.parse(result.value.registro)));
  }
}
```

## Capa Domain (opcional)

- **Modelos** (`domain/models/<funcionalidad>/`): entidades del negocio, mismas
  reglas que el DTO (inmutables, `fromJson`, `toJson`, `copyWith`, `toString`,
  `==`, `hashCode`). Son los que consume la UI. Los enums (`TipoMovimiento`,
  `RolUsuario`, `EstadoUsuario`) se definen como `enum` de Dart, uno por cada
  conjunto de la api; no reutilices uno ajeno.
- **Casos de uso** (`domain/use_cases/`): **solo** cuando la lógica es compleja o
  fusiona datos de varios repositorios, o se reutiliza en varios viewmodels. En
  funcionalidades simples omite la capa y el viewmodel usa el repositorio
  directo. Un caso de uso recibe repositorios por constructor, devuelve
  `Result<T>`, no depende de la UI y registra con `Logger`.
  Ejemplo del proyecto: el login (`POST /auth` -> guardar tokens ->
  `GET /usuarios/detalle` -> `SesionStore`) es un caso de uso porque combina
  varios pasos.

## Capa UI

### ViewModel (`ui/<funcionalidad>/viewmodels/`)

Extiende `ChangeNotifier`, está ligado a **una** vista y expone el estado a la
UI. Cada acción se encapsula en un `Command` y **debe devolver el mismo
`Result<T>` que entrega el repositorio** para que el comando reaccione a éxito o
error. Nombre: `<funcionalidad>_viewmodel.dart`.

```dart
class MovimientoViewmodel extends ChangeNotifier {
  MovimientoViewmodel({required MovimientoRepository movimientoRepository})
    : _movimientoRepository = movimientoRepository {
    registrar = Command1<MovimientoModel, (String, TipoMovimiento)>(_registrar);
  }

  final MovimientoRepository _movimientoRepository;
  late final Command1<MovimientoModel, (String, TipoMovimiento)> registrar;
  final Logger _log = Logger('MovimientoViewmodel');

  Future<Result<MovimientoModel>> _registrar((String, TipoMovimiento) datos) async {
    final (data, tipo) = datos;
    final result = await _movimientoRepository.registrar(data: data, tipo: tipo);
    if (result is Error<MovimientoModel>) {
      _log.warning('Error al registrar: ${result.error}');
    }
    return result;
  }
}
```

Para cargar al abrir la pantalla: `load = Command0(_load)..execute();` en el
constructor.

### Vista (`ui/<funcionalidad>/widgets/`)

- Punto de entrada: `<funcionalidad>_screen.dart` (`StatelessWidget`) que
  recibe el viewmodel y arma el `Scaffold`; pasa el viewmodel a los widgets hijos.
- Colores solo con `Theme.of(context).colorScheme.*` (nunca el hexadecimal) y
  medidas solo con `Dimens.of(context)`. Widgets globales desde
  `core/ui/widgets`. El nombre de la entidad sale de `Env`, nunca fijo.
- El resultado de una acción (éxito o error) se informa con el diálogo global de
  `core/ui/widgets`, no con uno propio de la pantalla. Un error muestra siempre
  `message` y, si `errors` no está vacío, sus pares campo -> mensaje.
- El widget que **reacciona a un comando** debe ser `StatefulWidget` y cumplir
  SIEMPRE estos 4 puntos, o la UI no reaccionará al volver a montarse y se
  duplicarán listeners:
  1. `initState`: `widget.viewModel.registrar.addListener(_onResult);`
  2. `_onResult`: llamar `clearResult()` **solo** cuando `completed` o `error`.
  3. `didUpdateWidget`: `removeListener` y luego `addListener`.
  4. `dispose`: `removeListener` antes de `super.dispose()`.
- Envuelve el contenido en `ListenableBuilder(listenable: viewModel.<comando>)`:
  si `error` muestra el aviso de error, si `running` un
  `CircularProgressIndicator`, si no el contenido.

```dart
class _RegistrarMovimientoWidgetState extends State<RegistrarMovimientoWidget> {
  final Logger _log = Logger('RegistrarMovimientoWidget');

  @override
  void initState() {
    super.initState();
    widget.viewModel.registrar.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant RegistrarMovimientoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.viewModel.registrar.removeListener(_onResult);
    widget.viewModel.registrar.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.registrar.removeListener(_onResult);
    super.dispose();
  }

  void _onResult() {
    if (widget.viewModel.registrar.completed) {
      widget.viewModel.registrar.clearResult();
      _log.info('Movimiento registrado');
    }
    if (widget.viewModel.registrar.error) {
      widget.viewModel.registrar.clearResult();
      _log.info('Error al registrar el movimiento');
    }
  }
}
```

## Configuración e integración

### Inyección de dependencias (`lib/config/dependencies.dart`)

Agrega los providers de la funcionalidad con `provider`, **en orden** (lo que se
usa en un provider posterior debe estar creado antes). Se registran: clientes de
api, repositorios, casos de uso y los stores globales (`TokenStore`,
`SesionStore`). **Nunca se registran los viewmodels**: mantienen estado aunque la
pantalla se destruya; se crean en el `builder` de la ruta. Castea cada
implementación a su interfaz.

```dart
List<SingleChildWidget> get appProviders {
  return [
    Provider(create: (context) => ApiClient(uri: Uri.parse(Env.apiUrl))),
    Provider(
      create: (context) =>
          MovimientoRepositoryImpl(apiClient: context.read()) as MovimientoRepository,
    ),
  ];
}
```

Los `appProviders` se montan con `MultiProvider` sobre el `MaterialApp.router`
en `main.dart`. Verifica que esté hecho y agrégalo si falta.

### Variables de entorno (`lib/config/env.dart`)

Se leen con `envied` desde `.env` (nunca urls escritas en el código). Si la
funcionalidad necesita una variable nueva: agrégala a `.env` y a `Env` con
`@EnviedField(varName: '...')`, y regenera:

```
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

`.env` y `env.g.dart` van en `.gitignore`. En el emulador de Android el backend
local se alcanza con `10.0.2.2`, no con `localhost`.

### Rutas (`lib/routing/`)

Un único `GoRouter`, sin prefijos por ambiente. Las rutas protegidas respetan el
`redirect` según `SesionStore` (estado `INICIAL` -> `/cambiar-clave`; rol
`GUARDIA` -> `/movimientos`; otro rol, rechazado).

```dart
class AppRoutes {
  static const login = '/login';
  static const movimientos = '/movimientos';
}
```

Registra la ruta en `app_router.dart`; el viewmodel se crea aquí con
`context.read()`:

```dart
GoRoute(
  path: AppRoutes.movimientos,
  builder: (context, state) => MovimientoScreen(
    viewmodel: MovimientoViewmodel(movimientoRepository: context.read()),
  ),
),
```

### Assets

Se declaran en `pubspec.yml` y se cargan por su ruta normal
(`Image.asset('assets/img/x.png')`). No uses `package:` ni `packages/<app>/`.

## Paquetes

Verifica que estén en `pubspec.yaml` y agrégalos si faltan:

```
flutter pub add provider go_router intl shared_preferences logging cached_network_image envied http mobile_scanner geolocator flutter_secure_storage
flutter pub add dev:build_runner dev:envied_generator dev:mocktail
```

Cámara y ubicación requieren permisos en `AndroidManifest.xml`
(`CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) y en `Info.plist`
(`NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`). Los tokens
se guardan solo a través de `TokenStore`, con `flutter_secure_storage`.

## Al terminar

1. Verifica: `dart format lib`, `flutter analyze` (y `flutter test` si hay
   pruebas). Corrige los errores antes de entregar.
2. Si durante el trabajo se tomó una decisión nueva de arquitectura o
   convención, agrégala a `MEMORY.md` en una línea.
3. Resume al usuario los archivos creados por capa, los providers agregados y la
   ruta registrada.