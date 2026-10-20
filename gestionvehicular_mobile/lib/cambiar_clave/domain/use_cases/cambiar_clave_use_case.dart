import 'package:logging/logging.dart';

import '../../../acceso_biometrico/data/repositories/acceso_biometrico_repository.dart';
import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../domain/models/sesion/usuario_model.dart';
import '../../../domain/stores/sesion_store.dart';
import '../../../inicio_sesion/data/repositories/autenticacion_repository.dart';
import '../reglas_clave.dart';

/// Caso de uso del cambio obligatorio de clave. Combina varios pasos, igual
/// que en la web de administración (`ChangePasswordUseCase`):
///
/// 1. valida la clave nueva contra las reglas del dominio;
/// 2. `POST /auth/change-password`, que devuelve **tokens nuevos**;
/// 3. `GET /usuarios/detalle` para releer el usuario, cuyo estado ya no es
///    `INICIAL`;
/// 4. publica el usuario en el [SesionStore], lo que hace que el `redirect`
///    del router deje salir de `/cambiar-clave`.
class CambiarClaveUseCase {
  CambiarClaveUseCase({
    required AutenticacionRepository autenticacionRepository,
    required AccesoBiometricoRepository accesoBiometricoRepository,
    required SesionStore sesionStore,
  }) : _autenticacionRepository = autenticacionRepository,
       _accesoBiometricoRepository = accesoBiometricoRepository,
       _sesionStore = sesionStore;

  final AutenticacionRepository _autenticacionRepository;
  final AccesoBiometricoRepository _accesoBiometricoRepository;
  final SesionStore _sesionStore;
  final Logger _log = Logger('CambiarClaveUseCase');

  /// Mensajes de las validaciones que se hacen antes de llamar a la api.
  static const mensajeSinSesion = 'No hay una sesión activa';
  static const mensajeClaveDebil =
      'La clave nueva no cumple las reglas de seguridad';
  static const mensajeClaveRepetida =
      'La clave nueva debe ser distinta de la actual';

  Future<Result<UsuarioModel>> ejecutar({
    required String claveActual,
    required String claveNueva,
  }) async {
    final correo = _sesionStore.usuario?.correo;
    if (correo == null) {
      return Result.error(const ApiException(mensajeSinSesion));
    }
    if (!claveEsValida(claveNueva)) {
      return Result.error(const ApiException(mensajeClaveDebil));
    }
    if (claveNueva == claveActual) {
      return Result.error(const ApiException(mensajeClaveRepetida));
    }

    final cambio = await _autenticacionRepository.cambiarClave(
      correo: correo,
      oldPassword: claveActual,
      newPassword: claveNueva,
    );
    if (cambio is Error<void>) {
      return Result.error(cambio.error);
    }

    // Con los tokens nuevos se relee el usuario: su estado deja de ser INICIAL.
    final detalle = await _autenticacionRepository.obtenerUsuarioActual();
    switch (detalle) {
      case Error<UsuarioModel>():
        // La clave sí cambió, pero no se pudo releer el usuario. Se descarta la
        // sesión para que vuelva a entrar con la clave nueva.
        _log.warning('Clave cambiada pero sin detalle: ${detalle.error}');
        await _autenticacionRepository.limpiarTokens();
        await _accesoBiometricoRepository.olvidar();
        _sesionStore.expirarSesion();
        return Result.error(detalle.error);
      case Ok<UsuarioModel>():
    }

    // El cambio de clave revocó los tokens anteriores: hay que recordar el
    // refresh token nuevo, o el acceso biométrico apuntaría a uno muerto.
    await _accesoBiometricoRepository.recordar();

    _sesionStore.establecerUsuario(detalle.value);
    _log.info('Clave cambiada; el usuario quedó en ${detalle.value.estado}');
    return Result.ok(detalle.value);
  }
}
