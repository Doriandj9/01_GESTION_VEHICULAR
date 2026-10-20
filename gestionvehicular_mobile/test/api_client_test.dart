import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:gestionvehicular_mobile/core/utils/result.dart';
import 'package:gestionvehicular_mobile/data/services/api/api_client.dart';
import 'package:gestionvehicular_mobile/data/stores/token_store.dart';

/// Cliente http falso que registra cada petición que recibe.
class _ClienteEspia extends http.BaseClient {
  _ClienteEspia(this._responder);

  final http.StreamedResponse Function(http.BaseRequest) _responder;
  final List<http.BaseRequest> peticiones = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    peticiones.add(request);
    return _responder(request);
  }
}

http.StreamedResponse _json(int codigo, Map<String, dynamic> cuerpo) {
  final bytes = utf8.encode(jsonEncode(cuerpo));
  return http.StreamedResponse(
    Stream.value(bytes),
    codigo,
    headers: {'content-type': 'application/json'},
  );
}

/// Almacenamiento seguro falso, en memoria.
class _AlmacenamientoFalso extends Mock implements FlutterSecureStorage {
  final Map<String, String> datos = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => datos[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      datos.remove(key);
    } else {
      datos[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    datos.remove(key);
  }
}

TokenStore _tokenStoreDePrueba() =>
    TokenStore(almacenamiento: _AlmacenamientoFalso());

void main() {
  late _ClienteEspia espia;

  test('GET /usuarios/detalle envía Authorization: Bearer', () async {
    espia = _ClienteEspia(
      (_) => _json(200, {
        'codUsuarios': 1,
        'nombres': 'Guardia',
        'correo': 'g@x.ec',
        'estado': 'ACTIVO',
        'rol': 'GUARDIA',
      }),
    );
    final tokenStore = _tokenStoreDePrueba();
    await tokenStore.guardar(jwt: 'JWT-123', refreshToken: 'RT-123');

    final cliente = ApiClient(
      uri: Uri.parse('http://localhost:8080/api/v1.0'),
      tokenStore: tokenStore,
      clientFactory: () => espia,
    );

    final resultado = await cliente.usuarioDetalle();

    expect(resultado, isA<Ok>());
    expect(espia.peticiones, hasLength(1));
    expect(
      espia.peticiones.single.url.toString(),
      'http://localhost:8080/api/v1.0/usuarios/detalle',
    );
    expect(espia.peticiones.single.headers['authorization'], 'Bearer JWT-123');
  });

  test('POST /auth no envía Authorization', () async {
    espia = _ClienteEspia(
      (_) =>
          _json(200, {'jwt': 'a', 'refreshToken': 'b', 'jwtExpired': 86400000}),
    );
    final cliente = ApiClient(
      uri: Uri.parse('http://localhost:8080/api/v1.0'),
      tokenStore: _tokenStoreDePrueba(),
      clientFactory: () => espia,
    );

    await cliente.login(correo: 'g@x.ec', password: 'x');

    expect(
      espia.peticiones.single.headers.containsKey('authorization'),
      isFalse,
    );
    expect(
      espia.peticiones.single.url.toString(),
      'http://localhost:8080/api/v1.0/auth',
    );
  });

  test('POST /auth/refresh envía el refresh token en la cabecera', () async {
    espia = _ClienteEspia(
      (_) =>
          _json(200, {'jwt': 'a', 'refreshToken': 'b', 'jwtExpired': 86400000}),
    );
    final cliente = ApiClient(
      uri: Uri.parse('http://localhost:8080/api/v1.0'),
      tokenStore: _tokenStoreDePrueba(),
      clientFactory: () => espia,
    );

    await cliente.refrescar('RT-123');

    // El backend autentica el refresco por la cabecera: sin ella responde
    // 400 "Token no encontrado.".
    expect(espia.peticiones.single.headers['authorization'], 'Bearer RT-123');
  });

  test('GET /movimientos/usuario manda cod y fecha como consulta', () async {
    espia = _ClienteEspia(
      (_) => http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode([
              {
                'codUsuarioRegistro': 7,
                'nombreUsuarioRegistro': 'Guardia',
                'fechaRegistro': '2026-10-19T08:15:00',
                'tipoMovimiento': 'SALIDA',
                'codVehiculo': 3,
                'placa': 'ABC-1234',
                'conductor': 'Juan Perez',
              },
            ]),
          ),
        ),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    final tokenStore = _tokenStoreDePrueba();
    await tokenStore.guardar(jwt: 'JWT-123', refreshToken: 'RT-123');

    final cliente = ApiClient(
      uri: Uri.parse('http://localhost:8080/api/v1.0'),
      tokenStore: tokenStore,
      clientFactory: () => espia,
    );

    final resultado = await cliente.listarMovimientosPorUsuario(
      codUsuario: 7,
      fecha: '2026-10-19T00:00:00',
    );

    expect(resultado, isA<Ok>());
    final url = espia.peticiones.single.url;
    expect(url.path, '/api/v1.0/movimientos/usuario');
    expect(url.queryParameters['cod'], '7');
    expect(url.queryParameters['fecha'], '2026-10-19T00:00:00');
    expect(espia.peticiones.single.headers['authorization'], 'Bearer JWT-123');
  });

  test(
    'GET /actuator/health va fuera del prefijo y sin Authorization',
    () async {
      espia = _ClienteEspia(
        (_) => _json(200, {
          'groups': ['liveness', 'readiness'],
          'status': 'UP',
        }),
      );
      final tokenStore = _tokenStoreDePrueba();
      await tokenStore.guardar(jwt: 'JWT-123', refreshToken: 'RT-123');

      final cliente = ApiClient(
        uri: Uri.parse('http://localhost:8080/api/v1.0'),
        tokenStore: tokenStore,
        clientFactory: () => espia,
      );

      final resultado = await cliente.consultarSalud();

      expect(resultado, isA<Ok>());
      expect(
        espia.peticiones.single.url.toString(),
        'http://localhost:8080/actuator/health',
      );
      expect(
        espia.peticiones.single.headers.containsKey('authorization'),
        isFalse,
      );
    },
  );

  test('un 503 del actuator se interpreta, no se descarta', () async {
    // Cuando un componente está caído, Spring responde 503 y el cuerpo trae
    // el estado: es justo lo que hay que mostrarle al guardia.
    espia = _ClienteEspia((_) => _json(503, {'status': 'DOWN'}));
    final cliente = ApiClient(
      uri: Uri.parse('http://localhost:8080/api/v1.0'),
      tokenStore: _tokenStoreDePrueba(),
      clientFactory: () => espia,
    );

    final resultado = await cliente.consultarSalud();

    expect(resultado, isA<Ok>());
    expect((resultado as Ok).value.status, 'DOWN');
  });

  test('ante 403 renueva el token y reintenta con el jwt nuevo', () async {
    var llamadas = 0;
    espia = _ClienteEspia((request) {
      final ruta = request.url.path;
      if (ruta.endsWith('/auth/refresh')) {
        return _json(200, {
          'jwt': 'JWT-NUEVO',
          'refreshToken': 'RT-NUEVO',
          'jwtExpired': 86400000,
        });
      }
      llamadas++;
      if (llamadas == 1) {
        return _json(403, {
          'timestamp': 'x',
          'status': 403,
          'error': 'Forbidden',
        });
      }
      return _json(200, {
        'codUsuarios': 1,
        'nombres': 'Guardia',
        'correo': 'g@x.ec',
        'estado': 'ACTIVO',
        'rol': 'GUARDIA',
      });
    });

    final tokenStore = _tokenStoreDePrueba();
    await tokenStore.guardar(jwt: 'JWT-VIEJO', refreshToken: 'RT-123');
    final cliente = ApiClient(
      uri: Uri.parse('http://localhost:8080/api/v1.0'),
      tokenStore: tokenStore,
      clientFactory: () => espia,
    );

    final resultado = await cliente.usuarioDetalle();

    expect(resultado, isA<Ok>());
    final detalles = espia.peticiones
        .where((p) => p.url.path.endsWith('/usuarios/detalle'))
        .toList();
    expect(detalles, hasLength(2));
    expect(detalles.first.headers['authorization'], 'Bearer JWT-VIEJO');
    expect(detalles.last.headers['authorization'], 'Bearer JWT-NUEVO');
  });
}
