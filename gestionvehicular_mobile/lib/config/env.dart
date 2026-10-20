import 'package:envied/envied.dart';

part 'env.g.dart';

/// Variables de entorno leídas del `.env` de la raíz.
/// Tras cambiar el `.env`:
/// `dart run build_runner clean` y
/// `dart run build_runner build --delete-conflicting-outputs`.
@Envied(path: '.env')
abstract final class Env {
  /// Url base del backend, sin barra final.
  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _Env.apiBaseUrl;

  /// Prefijo de la api, sin barra final.
  @EnviedField(varName: 'API_PREFIX')
  static const String apiPrefix = _Env.apiPrefix;

  /// Nombre completo de la entidad.
  @EnviedField(varName: 'ENTIDAD_NOMBRE')
  static const String entidadNombre = _Env.entidadNombre;

  /// Siglas de la entidad.
  @EnviedField(varName: 'ENTIDAD_ALIAS')
  static const String entidadAlias = _Env.entidadAlias;

  /// Url completa de la api (`apiBaseUrl` + `apiPrefix`).
  static String get apiUrl => '$apiBaseUrl$apiPrefix';
}
