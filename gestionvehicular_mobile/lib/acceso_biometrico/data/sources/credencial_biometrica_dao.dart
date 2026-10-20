import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/credencial_biometrica_model.dart';
import 'base_datos_local.dart';

/// Acceso a la credencial del acceso biométrico en sqlite. Guarda una sola
/// fila (`id = 1`): un dispositivo recuerda a un guardia.
///
/// El refresh token se guarda **codificado en base64**. Conviene tenerlo claro:
/// base64 no es cifrado, solo evita que el token se lea de un volcado de la
/// base de un vistazo. Lo que protege el acceso es la biometría del
/// dispositivo, y el jwt de la sesión activa sigue viviendo en
/// `flutter_secure_storage` a través del `TokenStore`.
class CredencialBiometricaDao {
  CredencialBiometricaDao({required BaseDatosLocal baseDatos})
    : _baseDatos = baseDatos;

  /// Clave primaria de la única fila de la tabla.
  static const idFila = 1;

  final BaseDatosLocal _baseDatos;
  final Logger _log = Logger('CredencialBiometricaDao');

  /// Guarda (o reemplaza) la credencial del dispositivo.
  Future<void> guardar(CredencialBiometricaModel credencial) async {
    try {
      final base = await _baseDatos.instancia;
      await base.insert(BaseDatosLocal.tablaCredencial, {
        'id': idFila,
        'correo': credencial.correo,
        'refresh_token_b64': _codificar(credencial.refreshToken),
        'expira_en': credencial.expiraEn.millisecondsSinceEpoch,
        'guardada_en': credencial.guardadaEn.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _log.info('Credencial biométrica guardada: $credencial');
    } on Exception catch (e) {
      // Si no se pudo guardar, el guardia simplemente entrará con su clave.
      _log.warning('No se pudo guardar la credencial: $e');
    }
  }

  /// Credencial guardada, o `null` si no hay ninguna o está ilegible.
  Future<CredencialBiometricaModel?> leer() async {
    try {
      final base = await _baseDatos.instancia;
      final filas = await base.query(
        BaseDatosLocal.tablaCredencial,
        where: 'id = ?',
        whereArgs: [idFila],
        limit: 1,
      );
      if (filas.isEmpty) return null;
      return _aModelo(filas.single);
    } on Exception catch (e) {
      _log.warning('No se pudo leer la credencial: $e');
      return null;
    }
  }

  /// Borra la credencial del dispositivo.
  Future<void> borrar() async {
    try {
      final base = await _baseDatos.instancia;
      final filas = await base.delete(
        BaseDatosLocal.tablaCredencial,
        where: 'id = ?',
        whereArgs: [idFila],
      );
      _log.info('Credencial biométrica borrada ($filas fila/s)');
    } on Exception catch (e) {
      _log.warning('No se pudo borrar la credencial: $e');
    }
  }

  CredencialBiometricaModel? _aModelo(Map<String, Object?> fila) {
    final correo = fila['correo'];
    final tokenB64 = fila['refresh_token_b64'];
    final expiraEn = fila['expira_en'];
    final guardadaEn = fila['guardada_en'];
    if (correo is! String || tokenB64 is! String || expiraEn is! int) {
      _log.warning('Fila de credencial incompleta: se descarta');
      return null;
    }

    final token = _decodificar(tokenB64);
    if (token == null) return null;

    return CredencialBiometricaModel(
      correo: correo,
      refreshToken: token,
      expiraEn: DateTime.fromMillisecondsSinceEpoch(expiraEn, isUtc: true),
      guardadaEn: DateTime.fromMillisecondsSinceEpoch(
        guardadaEn is int ? guardadaEn : expiraEn,
        isUtc: true,
      ),
    );
  }

  String _codificar(String token) => base64Encode(utf8.encode(token));

  String? _decodificar(String tokenB64) {
    try {
      return utf8.decode(base64Decode(tokenB64));
    } on Exception catch (e) {
      _log.warning('La credencial guardada no se pudo decodificar: $e');
      return null;
    }
  }
}
