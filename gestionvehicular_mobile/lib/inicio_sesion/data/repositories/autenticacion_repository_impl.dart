import 'package:logging/logging.dart';

import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../data/services/api/api_client.dart';
import '../../../data/stores/token_store.dart';
import '../../../domain/models/sesion/usuario_model.dart';
import '../models/auth_response_api_model.dart';
import '../models/usuario_detalle_api_model.dart';
import 'autenticacion_repository.dart';

/// Implementación de [AutenticacionRepository] sobre el `ApiClient` y el
/// `TokenStore`. Transforma los DTO de la api a modelos de dominio: la ui
/// nunca ve un `*ApiModel`.
class AutenticacionRepositoryImpl extends AutenticacionRepository {
  AutenticacionRepositoryImpl({
    required ApiClient apiClient,
    required TokenStore tokenStore,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  final Logger _log = Logger('AutenticacionRepositoryImpl');

  @override
  Future<Result<void>> autenticar({
    required String correo,
    required String password,
  }) async {
    final resultado = await _apiClient.login(
      correo: correo,
      password: password,
    );
    switch (resultado) {
      case Error<AuthResponseApiModel>():
        _log.warning('Fallo la autenticacion: ${resultado.error}');
        return Result.error(resultado.error);
      case Ok<AuthResponseApiModel>():
    }

    await _tokenStore.guardar(
      jwt: resultado.value.jwt,
      refreshToken: resultado.value.refreshToken,
    );
    _log.info('Credenciales validadas y tokens guardados');
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> refrescarSesion(String refreshToken) async {
    final resultado = await _apiClient.refrescar(refreshToken);
    switch (resultado) {
      case Error<AuthResponseApiModel>():
        _log.warning('Fallo el refresco de la sesion: ${resultado.error}');
        return Result.error(resultado.error);
      case Ok<AuthResponseApiModel>():
    }

    await _tokenStore.guardar(
      jwt: resultado.value.jwt,
      refreshToken: resultado.value.refreshToken,
    );
    _log.info('Sesion refrescada y tokens reemplazados');
    return const Result.ok(null);
  }

  @override
  Future<Result<UsuarioModel>> obtenerUsuarioActual() async {
    final resultado = await _apiClient.usuarioDetalle();
    switch (resultado) {
      case Error<UsuarioDetalleApiModel>():
        _log.warning('No se pudo obtener el detalle: ${resultado.error}');
        return Result.error(resultado.error);
      case Ok<UsuarioDetalleApiModel>():
    }

    // El dto trae `rol` y `estado` como texto plano: aquí se pasan a los enums
    // del dominio, y un valor desconocido se trata como error de la api.
    try {
      final dto = resultado.value;
      return Result.ok(
        UsuarioModel.fromJson({
          'codUsuarios': dto.codUsuarios,
          'nombres': dto.nombres,
          'correo': dto.correo,
          'estado': dto.estado,
          'rol': dto.rol,
        }),
      );
    } on ArgumentError catch (e) {
      _log.severe('Detalle de usuario no reconocido: $e');
      return Result.error(const ApiException(ApiErrors.mensajeGenerico));
    }
  }

  @override
  Future<Result<void>> cambiarClave({
    required String correo,
    required String oldPassword,
    required String newPassword,
  }) async {
    final resultado = await _apiClient.cambiarClave(
      correo: correo,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    switch (resultado) {
      case Error<AuthResponseApiModel>():
        _log.warning('Fallo el cambio de clave: ${resultado.error}');
        return Result.error(resultado.error);
      case Ok<AuthResponseApiModel>():
    }

    // La api devuelve tokens nuevos: los viejos dejan de servir.
    await _tokenStore.guardar(
      jwt: resultado.value.jwt,
      refreshToken: resultado.value.refreshToken,
    );
    _log.info('Clave cambiada y tokens reemplazados');
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> cerrarSesion() async {
    final refreshToken = await _tokenStore.obtenerRefreshToken();
    Result<void> resultado = const Result.ok(null);
    if (refreshToken != null) {
      resultado = await _apiClient.logout(refreshToken);
      if (resultado is Error<void>) {
        _log.warning('El logout de la api fallo: ${resultado.error}');
      }
    }
    // Falle o no la api, la sesión local siempre se limpia.
    await _tokenStore.limpiar();
    return resultado;
  }

  @override
  Future<bool> haySesionGuardada() => _tokenStore.haySesionGuardada;

  @override
  Future<void> limpiarTokens() => _tokenStore.limpiar();
}
