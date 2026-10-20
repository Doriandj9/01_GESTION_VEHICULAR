import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gestionvehicular_mobile/acceso_biometrico/data/services/biometria_service.dart';
import 'package:gestionvehicular_mobile/acceso_biometrico/domain/jwt_payload.dart';
import 'package:gestionvehicular_mobile/acceso_biometrico/domain/models/credencial_biometrica_model.dart';
import 'package:gestionvehicular_mobile/acceso_biometrico/domain/use_cases/iniciar_sesion_biometrica_use_case.dart';
import 'package:gestionvehicular_mobile/core/utils/result.dart';
import 'package:gestionvehicular_mobile/domain/models/sesion/usuario_model.dart';
import 'package:gestionvehicular_mobile/domain/stores/sesion_store.dart';
import 'package:gestionvehicular_mobile/inicio_sesion/data/repositories/autenticacion_repository.dart';

import 'dobles/acceso_biometrico_falso.dart';

class _AutenticacionRepositoryFalso extends Mock
    implements AutenticacionRepository {}

UsuarioModel _usuario({String rol = 'GUARDIA'}) => UsuarioModel.fromJson({
  'codUsuarios': 7,
  'nombres': 'Guardia de prueba',
  'correo': 'guardia@gadmjs.gob.ec',
  'estado': 'ACTIVO',
  'rol': rol,
});

/// Arma un jwt con la misma forma que el del backend (`sub`, `iat`, `exp`),
/// con la firma como relleno: el móvil nunca la verifica.
String _jwt({
  String sub = 'guardia@gadmjs.gob.ec',
  Duration vigencia = const Duration(days: 7),
}) {
  String parte(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final ahora = DateTime.now().toUtc();
  return '${parte({'alg': 'HS256'})}.'
      '${parte({'sub': sub, 'iat': ahora.millisecondsSinceEpoch ~/ 1000, 'exp': ahora.add(vigencia).millisecondsSinceEpoch ~/ 1000})}.firma';
}

void main() {
  group('JwtPayload', () {
    test('lee el correo y la caducidad de un token del backend', () {
      final payload = JwtPayload.desdeToken(_jwt());

      expect(payload, isNotNull);
      expect(payload!.sub, 'guardia@gadmjs.gob.ec');
      // La caducidad sale de `exp`, no de `iat`: `iat` es la emisión.
      expect(payload.exp.isAfter(payload.iat), isTrue);
      expect(payload.caducado, isFalse);
      expect(payload.vigenciaRestante.inDays, 6);
    });

    test('marca caducado un token ya vencido', () {
      final payload = JwtPayload.desdeToken(
        _jwt(vigencia: const Duration(days: -1)),
      );

      expect(payload!.caducado, isTrue);
      expect(payload.vigenciaRestante, Duration.zero);
    });

    test('devuelve null ante un token que no es un jwt', () {
      expect(JwtPayload.desdeToken('esto-no-es-un-jwt'), isNull);
      expect(JwtPayload.desdeToken('a.b.c'), isNull);
      expect(JwtPayload.desdeToken(''), isNull);
    });
  });

  group('CredencialBiometricaModel', () {
    test('se arma desde el refresh token sin datos de fuera', () {
      final credencial = CredencialBiometricaModel.desdeRefreshToken(_jwt());

      expect(credencial, isNotNull);
      expect(credencial!.correo, 'guardia@gadmjs.gob.ec');
      expect(credencial.caducada, isFalse);
    });

    test('una credencial vencida se declara caducada', () {
      final credencial = CredencialBiometricaModel.desdeRefreshToken(
        _jwt(vigencia: const Duration(hours: -1)),
      );

      expect(credencial!.caducada, isTrue);
    });

    test('el toString no expone el token', () {
      final credencial = credencialDePrueba(refreshToken: 'SECRETO-123');

      expect(credencial.toString(), isNot(contains('SECRETO-123')));
    });
  });

  group('IniciarSesionBiometricaUseCase', () {
    late _AutenticacionRepositoryFalso autenticacion;
    late AccesoBiometricoFalso accesoBiometrico;
    late SesionStore sesionStore;
    late IniciarSesionBiometricaUseCase useCase;

    setUp(() {
      autenticacion = _AutenticacionRepositoryFalso();
      accesoBiometrico = AccesoBiometricoFalso(
        credencial: credencialDePrueba(),
      );
      sesionStore = SesionStore(autenticacionRepository: autenticacion);
      useCase = IniciarSesionBiometricaUseCase(
        accesoBiometricoRepository: accesoBiometrico,
        autenticacionRepository: autenticacion,
        sesionStore: sesionStore,
      );
      when(() => autenticacion.limpiarTokens()).thenAnswer((_) async {});
    });

    test('refresca la sesión y publica al guardia tras la huella', () async {
      when(() => autenticacion.refrescarSesion(any()))
          .thenAnswer((_) async => const Result.ok(null));
      when(() => autenticacion.obtenerUsuarioActual())
          .thenAnswer((_) async => Result.ok(_usuario()));

      final resultado = await useCase.ejecutar();

      expect(resultado, isA<Ok<UsuarioModel>>());
      expect(sesionStore.usuario?.correo, 'guardia@gadmjs.gob.ec');
      verify(() => autenticacion.refrescarSesion('RT-GUARDADO')).called(1);
      // El refresco revoca el token anterior: hay que recordar el nuevo.
      expect(accesoBiometrico.vecesRecordada, 1);
    });

    test('no pide la huella si no hay credencial guardada', () async {
      accesoBiometrico.credencial = null;

      final resultado = await useCase.ejecutar();

      expect(resultado, isA<Error<UsuarioModel>>());
      expect(accesoBiometrico.vecesComprobada, 0);
      verifyNever(() => autenticacion.refrescarSesion(any()));
    });

    test('no refresca si la biometría no autoriza', () async {
      accesoBiometrico.identidad = ResultadoBiometria.rechazado;

      final resultado = await useCase.ejecutar();

      expect(resultado, isA<Error<UsuarioModel>>());
      verifyNever(() => autenticacion.refrescarSesion(any()));
      // La credencial sigue ahí: una huella equivocada no la invalida.
      expect(accesoBiometrico.vecesOlvidada, 0);
    });

    test('olvida la credencial si el backend rechaza el refresco', () async {
      when(() => autenticacion.refrescarSesion(any()))
          .thenAnswer((_) async => Result.error(Exception('token revocado')));

      final resultado = await useCase.ejecutar();

      expect(resultado, isA<Error<UsuarioModel>>());
      expect(accesoBiometrico.vecesOlvidada, 1);
      expect(accesoBiometrico.credencial, isNull);
    });

    test('rechaza y olvida a quien no es guardia', () async {
      when(() => autenticacion.refrescarSesion(any()))
          .thenAnswer((_) async => const Result.ok(null));
      when(() => autenticacion.obtenerUsuarioActual())
          .thenAnswer((_) async => Result.ok(_usuario(rol: 'ADMINISTRADOR')));

      final resultado = await useCase.ejecutar();

      expect(resultado, isA<Error<UsuarioModel>>());
      expect(sesionStore.usuario, isNull);
      expect(accesoBiometrico.vecesOlvidada, 1);
      verify(() => autenticacion.limpiarTokens()).called(1);
    });
  });
}
