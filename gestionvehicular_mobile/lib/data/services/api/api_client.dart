import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../inicio_sesion/data/models/auth_response_api_model.dart';
import '../../../inicio_sesion/data/models/usuario_detalle_api_model.dart';
import '../../../movimientos/data/models/movimiento_api_model.dart';
import '../../../movimientos/data/models/movimiento_registrado_api_model.dart';
import '../../../salud_servidor/data/models/salud_api_model.dart';
import '../../stores/token_store.dart';

/// Único cliente http de la app. Cada funcionalidad agrega aquí su método por
/// endpoint; no se crea otro cliente.
///
/// Reglas que viven aquí y no se duplican por funcionalidad:
/// - cada petición abre un `http.Client` nuevo y lo cierra en el `finally`;
/// - `POST /auth` es el único endpoint sin `Authorization`; el resto la lleva
///   con el jwt, salvo `/auth/refresh`, que la lleva con el **refresh token**
///   porque el filtro del backend exige tipo `REFRESH_TOKEN` en esa ruta;
/// - el nombre de la cabecera sale en minúscula (`authorization`) porque
///   `dart:io` lo normaliza así; es válido y el backend la lee con
///   `request.getHeader`, que es insensible a mayúsculas;
/// - ante 401/403 renueva el token y reintenta la petición **una sola vez**
///   (no reintenta `/auth/change-password` ni `/auth/logout`);
/// - los refrescos simultáneos comparten una única llamada a `/auth/refresh`.
class ApiClient {
  ApiClient({
    required Uri uri,
    required TokenStore tokenStore,
    http.Client Function()? clientFactory,
  }) : _uri = uri,
       _tokenStore = tokenStore,
       _clientFactory = clientFactory ?? (() => http.Client());

  final Uri _uri;
  final TokenStore _tokenStore;
  final http.Client Function() _clientFactory;
  final Logger _log = Logger('ApiClient');

  static const _tiempoMaximo = Duration(seconds: 20);

  /// Tiempo máximo del sondeo de salud, más corto que el del resto: bloquea el
  /// arranque de la app.
  static const _tiempoMaximoSalud = Duration(seconds: 8);

  /// Ruta del actuator. Es absoluta porque vive fuera del prefijo de la api.
  static const rutaSalud = '/actuator/health';

  /// Aviso a la capa de sesión de que el jwt ya no sirve y no se pudo renovar.
  /// Se asigna en `dependencies.dart` para no acoplar el cliente al store.
  void Function()? alExpirarSesion;

  /// Aviso de que el par de tokens se reemplazó en un refresco silencioso. El
  /// backend revoca el refresh token anterior en cada refresco, así que quien
  /// lo tenga guardado (el acceso biométrico) debe actualizarlo.
  /// Se asigna en `dependencies.dart`.
  void Function()? alRenovarTokens;

  /// Llamada en curso a `/auth/refresh`, compartida por los refrescos
  /// simultáneos para no renovar el token varias veces a la vez.
  Future<bool>? _refrescoEnCurso;

  Uri _url(String ruta) => _uri.replace(path: '${_uri.path}$ruta');

  Map<String, String> _cabeceras({String? jwt}) => {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.acceptHeader: 'application/json',
    if (jwt != null) HttpHeaders.authorizationHeader: 'Bearer $jwt',
  };

  // --------------------------------------------------------------------------
  // Autenticación
  // --------------------------------------------------------------------------

  /// `POST /auth`. Único endpoint público: no lleva `Authorization`.
  Future<Result<AuthResponseApiModel>> login({
    required String correo,
    required String password,
  }) async {
    return _peticionSinSesion(
      ruta: '/auth',
      cuerpo: {'correo': correo, 'password': password},
      parsear: AuthResponseApiModel.fromJson,
    );
  }

  /// `POST /auth/refresh`. El servicio del backend usa el cuerpo `{ token }`,
  /// y su filtro, si llega cabecera, exige que el token sea de tipo
  /// `REFRESH_TOKEN`. Por eso el refresh token va en los dos sitios.
  ///
  /// No pasa por `_peticionAutenticada` a propósito: el token de aquí es el
  /// refresh token, no el jwt del `TokenStore`, y no se puede reintentar.
  Future<Result<AuthResponseApiModel>> refrescar(String refreshToken) async {
    return _peticionSinSesion(
      ruta: '/auth/refresh',
      cuerpo: {'token': refreshToken},
      parsear: AuthResponseApiModel.fromJson,
      token: refreshToken,
    );
  }

  /// `POST /auth/logout`. No se reintenta: aquí un 401 es error de negocio.
  Future<Result<void>> logout(String refreshToken) async {
    final resultado = await _peticionAutenticada<Map<String, dynamic>>(
      ruta: '/auth/logout',
      metodo: 'POST',
      cuerpo: {'token': refreshToken},
      parsear: (json) => json,
      reintentar: false,
    );
    return switch (resultado) {
      Ok<Map<String, dynamic>>() => const Result.ok(null),
      Error<Map<String, dynamic>>() => Result.error(resultado.error),
    };
  }

  /// `POST /auth/change-password`. Devuelve tokens nuevos; no se reintenta.
  Future<Result<AuthResponseApiModel>> cambiarClave({
    required String correo,
    required String oldPassword,
    required String newPassword,
  }) async {
    return _peticionAutenticada(
      ruta: '/auth/change-password',
      metodo: 'POST',
      cuerpo: {
        'correo': correo,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
      parsear: AuthResponseApiModel.fromJson,
      reintentar: false,
    );
  }

  // --------------------------------------------------------------------------
  // Salud del servidor
  // --------------------------------------------------------------------------

  /// `GET /actuator/health`. Va **fuera** del prefijo de la api (`/api/v1.0`)
  /// y sin `Authorization`: en el backend `/actuator/**` es `permitAll`.
  ///
  /// El cuerpo se interpreta aunque el código no sea 2xx: cuando un componente
  /// está caído, Spring responde **503 con `{"status":"DOWN"}`**, y ese cuerpo
  /// es justo lo que hay que mostrar. Solo es error lo que no se pueda leer.
  ///
  /// Lleva un tiempo máximo más corto que el resto: es lo primero que hace la
  /// app al abrirse y no se deja al guardia esperando.
  Future<Result<SaludApiModel>> consultarSalud() async {
    final client = _clientFactory();
    final url = _uri.replace(path: rutaSalud);
    try {
      final respuesta = await client
          .get(url, headers: _cabeceras())
          .timeout(_tiempoMaximoSalud);
      _log.info('Respuesta de $url: ${respuesta.statusCode}');
      final texto = utf8.decode(respuesta.bodyBytes);
      if (texto.trim().isEmpty) {
        return Result.error(ApiErrors.desdeRespuesta(respuesta));
      }
      final json = jsonDecode(texto) as Map<String, dynamic>;
      final salud = SaludApiModel.fromJson(json);
      if (salud.status.isEmpty) {
        return Result.error(ApiErrors.desdeRespuesta(respuesta));
      }
      return Result.ok(salud);
    } on Exception catch (e) {
      _log.warning('No se pudo consultar la salud en $url: $e');
      return Result.error(ApiErrors.desdeExcepcion(e));
    } finally {
      client.close();
    }
  }

  // --------------------------------------------------------------------------
  // Usuario de la sesión
  // --------------------------------------------------------------------------

  /// `GET /usuarios/detalle`. Devuelve el usuario dueño del jwt.
  Future<Result<UsuarioDetalleApiModel>> usuarioDetalle() async {
    return _peticionAutenticada(
      ruta: '/usuarios/detalle',
      metodo: 'GET',
      parsear: UsuarioDetalleApiModel.fromJson,
    );
  }

  // --------------------------------------------------------------------------
  // Movimientos
  // --------------------------------------------------------------------------

  /// `POST /movimientos`. `data` es el texto del QR del vehículo; `latitud` y
  /// `longitud` son opcionales y se omiten si el guardia negó el permiso.
  ///
  /// Un movimiento rechazado puede responder **200 con `estado: ERROR`**: eso
  /// lo interpreta el repositorio, no este cliente.
  Future<Result<MovimientoApiModel>> registrarMovimiento({
    required String data,
    required String tipo,
    double? latitud,
    double? longitud,
  }) async {
    return _peticionAutenticada(
      ruta: '/movimientos',
      metodo: 'POST',
      cuerpo: {
        'data': data,
        'tipo': tipo,
        'latitud': ?latitud,
        'longitud': ?longitud,
      },
      parsear: MovimientoApiModel.fromJson,
    );
  }

  /// `GET /movimientos/usuario?cod=<codUsuarios>&fecha=<date-time>`.
  ///
  /// Devuelve los movimientos que **registró** ese usuario desde [fecha]
  /// (inclusive), ordenados de más reciente a más antiguo. `fecha` va como
  /// `yyyy-MM-ddTHH:mm:ss`, el formato que lee el backend.
  Future<Result<List<MovimientoRegistradoApiModel>>>
  listarMovimientosPorUsuario({
    required int codUsuario,
    required String fecha,
  }) async {
    return _peticionAutenticadaLista(
      ruta: '/movimientos/usuario',
      metodo: 'GET',
      consulta: {'cod': '$codUsuario', 'fecha': fecha},
      parsear: MovimientoRegistradoApiModel.fromJson,
    );
  }

  // --------------------------------------------------------------------------
  // Mecánica interna
  // --------------------------------------------------------------------------

  /// Petición que no usa el jwt del `TokenStore`: `/auth` (sin cabecera) y
  /// `/auth/refresh` (con el refresh token en la cabecera, vía [token]).
  Future<Result<T>> _peticionSinSesion<T>({
    required String ruta,
    required Map<String, dynamic> cuerpo,
    required T Function(Map<String, dynamic>) parsear,
    String? token,
  }) async {
    final client = _clientFactory();
    final url = _url(ruta);
    try {
      final respuesta = await client
          .post(
            url,
            headers: _cabeceras(jwt: token),
            body: jsonEncode(cuerpo),
          )
          .timeout(_tiempoMaximo);
      _log.info('Respuesta de $url: ${respuesta.statusCode}');
      return _interpretar(respuesta, parsear);
    } on Exception catch (e) {
      _log.warning('Fallo la peticion a $url: $e');
      return Result.error(ApiErrors.desdeExcepcion(e));
    } finally {
      client.close();
    }
  }

  /// Petición con `Authorization` cuya respuesta es un objeto json.
  Future<Result<T>> _peticionAutenticada<T>({
    required String ruta,
    required String metodo,
    required T Function(Map<String, dynamic>) parsear,
    Map<String, dynamic>? cuerpo,
    Map<String, String>? consulta,
    bool reintentar = true,
  }) async {
    final respuesta = await _respuestaAutenticada(
      ruta: ruta,
      metodo: metodo,
      cuerpo: cuerpo,
      consulta: consulta,
      reintentar: reintentar,
    );
    return switch (respuesta) {
      Error<http.Response>() => Result.error(respuesta.error),
      Ok<http.Response>() => _interpretar(respuesta.value, parsear),
    };
  }

  /// Igual que [_peticionAutenticada], pero cuando la respuesta es un **arreglo**
  /// json: cada elemento se pasa por `parsear`.
  Future<Result<List<T>>> _peticionAutenticadaLista<T>({
    required String ruta,
    required String metodo,
    required T Function(Map<String, dynamic>) parsear,
    Map<String, dynamic>? cuerpo,
    Map<String, String>? consulta,
  }) async {
    final respuesta = await _respuestaAutenticada(
      ruta: ruta,
      metodo: metodo,
      cuerpo: cuerpo,
      consulta: consulta,
      reintentar: true,
    );
    return switch (respuesta) {
      Error<http.Response>() => Result.error(respuesta.error),
      Ok<http.Response>() => _interpretarLista(respuesta.value, parsear),
    };
  }

  /// Envía la petición autenticada y, ante 401/403, renueva el token y la
  /// repite **una sola vez** cuando `reintentar` es `true`.
  Future<Result<http.Response>> _respuestaAutenticada({
    required String ruta,
    required String metodo,
    required bool reintentar,
    Map<String, dynamic>? cuerpo,
    Map<String, String>? consulta,
  }) async {
    final respuesta = await _enviarAutenticada(
      ruta: ruta,
      metodo: metodo,
      cuerpo: cuerpo,
      consulta: consulta,
    );
    switch (respuesta) {
      case Error<http.Response>():
        return Result.error(respuesta.error);
      case Ok<http.Response>():
    }

    final codigo = respuesta.value.statusCode;
    final esSesionInvalida = codigo == 401 || codigo == 403;
    if (!esSesionInvalida || !reintentar) {
      return respuesta;
    }

    // El jwt pudo caducar: se renueva y se repite la petición una sola vez.
    final renovado = await _refrescarToken();
    if (!renovado) {
      return Result.error(const ApiException(ApiErrors.mensajeSesionExpirada));
    }
    return _enviarAutenticada(
      ruta: ruta,
      metodo: metodo,
      cuerpo: cuerpo,
      consulta: consulta,
    );
  }

  Future<Result<http.Response>> _enviarAutenticada({
    required String ruta,
    required String metodo,
    Map<String, dynamic>? cuerpo,
    Map<String, String>? consulta,
  }) async {
    final jwt = await _tokenStore.obtenerJwt();
    if (jwt == null) {
      return Result.error(const ApiException(ApiErrors.mensajeSesionExpirada));
    }

    final client = _clientFactory();
    final base = _url(ruta);
    final url = consulta == null
        ? base
        : base.replace(queryParameters: consulta);
    final cabeceras = _cabeceras(jwt: jwt);
    try {
      final peticion = switch (metodo) {
        'GET' => client.get(url, headers: cabeceras),
        'POST' => client.post(
          url,
          headers: cabeceras,
          body: jsonEncode(cuerpo ?? const <String, dynamic>{}),
        ),
        _ => throw ArgumentError('Método http no soportado: $metodo'),
      };
      final respuesta = await peticion.timeout(_tiempoMaximo);
      _log.info('Respuesta de $url: ${respuesta.statusCode}');
      return Result.ok(respuesta);
    } on Exception catch (e) {
      _log.warning('Fallo la peticion a $url: $e');
      return Result.error(ApiErrors.desdeExcepcion(e));
    } finally {
      client.close();
    }
  }

  /// Renueva el jwt. Los refrescos simultáneos esperan la misma llamada.
  Future<bool> _refrescarToken() {
    return _refrescoEnCurso ??= _hacerRefresco().whenComplete(() {
      _refrescoEnCurso = null;
    });
  }

  Future<bool> _hacerRefresco() async {
    final refreshToken = await _tokenStore.obtenerRefreshToken();
    if (refreshToken == null) {
      alExpirarSesion?.call();
      return false;
    }

    final resultado = await refrescar(refreshToken);
    switch (resultado) {
      case Ok<AuthResponseApiModel>():
        await _tokenStore.guardar(
          jwt: resultado.value.jwt,
          refreshToken: resultado.value.refreshToken,
        );
        _log.info('Token renovado');
        alRenovarTokens?.call();
        return true;
      case Error<AuthResponseApiModel>():
        // Cualquier error del refresco (incluido el 500) marca la sesión como
        // expirada: no hay forma de recuperar el jwt.
        _log.warning('No se pudo renovar el token: ${resultado.error}');
        alExpirarSesion?.call();
        return false;
    }
  }

  /// Igual que [_interpretar], pero para un 2xx cuyo cuerpo es un arreglo json.
  /// Un cuerpo vacío se resuelve como lista vacía.
  Result<List<T>> _interpretarLista<T>(
    http.Response respuesta,
    T Function(Map<String, dynamic>) parsear,
  ) {
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      return Result.error(ApiErrors.desdeRespuesta(respuesta));
    }
    try {
      final texto = utf8.decode(respuesta.bodyBytes);
      if (texto.trim().isEmpty) return Result.ok(const []);
      final json = jsonDecode(texto) as List<dynamic>;
      return Result.ok(
        json.cast<Map<String, dynamic>>().map(parsear).toList(growable: false),
      );
    } on Exception catch (e) {
      _log.warning('No se pudo interpretar la lista: $e');
      return Result.error(const ApiException(ApiErrors.mensajeGenerico));
    }
  }

  /// Convierte una respuesta http en `Result`. Un 2xx sin cuerpo se resuelve
  /// con un mapa vacío para que `parsear` siempre reciba json.
  Result<T> _interpretar<T>(
    http.Response respuesta,
    T Function(Map<String, dynamic>) parsear,
  ) {
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      return Result.error(ApiErrors.desdeRespuesta(respuesta));
    }
    try {
      final texto = utf8.decode(respuesta.bodyBytes);
      final json = texto.trim().isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(texto) as Map<String, dynamic>;
      return Result.ok(parsear(json));
    } on Exception catch (e) {
      _log.warning('No se pudo interpretar la respuesta: $e');
      return Result.error(const ApiException(ApiErrors.mensajeGenerico));
    }
  }
}
