import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

/// Único punto de acceso al jwt y al refresh token. Ninguna otra clase toca el
/// almacenamiento seguro directamente. Se usa `flutter_secure_storage` porque
/// los tokens son credenciales.
class TokenStore {
  TokenStore({FlutterSecureStorage? almacenamiento})
    : _almacenamiento = almacenamiento ?? const FlutterSecureStorage();

  static const claveJwt = 'gv_jwt';
  static const claveRefreshToken = 'gv_refresh_token';

  final FlutterSecureStorage _almacenamiento;
  final Logger _log = Logger('TokenStore');

  /// Caché en memoria para no leer el almacenamiento en cada petición.
  String? _jwt;
  String? _refreshToken;
  bool _cargado = false;

  Future<void> _cargar() async {
    if (_cargado) return;
    try {
      _jwt = await _almacenamiento.read(key: claveJwt);
      _refreshToken = await _almacenamiento.read(key: claveRefreshToken);
    } on Exception catch (e) {
      _log.warning('No se pudieron leer los tokens: $e');
      _jwt = null;
      _refreshToken = null;
    }
    _cargado = true;
  }

  /// Jwt vigente, o `null` si no hay sesión guardada.
  Future<String?> obtenerJwt() async {
    await _cargar();
    return _jwt;
  }

  /// Refresh token guardado, o `null`.
  Future<String?> obtenerRefreshToken() async {
    await _cargar();
    return _refreshToken;
  }

  /// `true` si hay un jwt guardado (no valida su vigencia).
  Future<bool> get haySesionGuardada async => (await obtenerJwt()) != null;

  /// Guarda el par de tokens devuelto por `/auth`, `/auth/refresh` o
  /// `/auth/change-password`.
  Future<void> guardar({
    required String jwt,
    required String refreshToken,
  }) async {
    _jwt = jwt;
    _refreshToken = refreshToken;
    _cargado = true;
    try {
      await _almacenamiento.write(key: claveJwt, value: jwt);
      await _almacenamiento.write(key: claveRefreshToken, value: refreshToken);
    } on Exception catch (e) {
      _log.warning('No se pudieron guardar los tokens: $e');
    }
  }

  /// Borra los tokens del dispositivo y de la caché.
  Future<void> limpiar() async {
    _jwt = null;
    _refreshToken = null;
    _cargado = true;
    try {
      await _almacenamiento.delete(key: claveJwt);
      await _almacenamiento.delete(key: claveRefreshToken);
    } on Exception catch (e) {
      _log.warning('No se pudieron borrar los tokens: $e');
    }
  }
}
