import 'package:logging/logging.dart';

import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../domain/models/sesion/rol_usuario.dart';
import '../../../domain/models/sesion/usuario_model.dart';
import '../../../acceso_biometrico/data/repositories/acceso_biometrico_repository.dart';
import '../../../domain/stores/sesion_store.dart';
import '../../data/repositories/autenticacion_repository.dart';

/// Caso de uso del login. Existe porque el inicio de sesión combina varios
/// pasos y una regla de negocio propia del móvil:
///
/// 1. `POST /auth` y guardado de los tokens;
/// 2. `GET /usuarios/detalle` para conocer al usuario y su rol;
/// 3. rechazo de cualquier rol distinto de `GUARDIA` (limpiando la sesión);
/// 4. publicación del usuario en el [SesionStore];
/// 5. memoria del refresh token para el siguiente ingreso con biometría.
class IniciarSesionUseCase {
  IniciarSesionUseCase({
    required AutenticacionRepository autenticacionRepository,
    required AccesoBiometricoRepository accesoBiometricoRepository,
    required SesionStore sesionStore,
  }) : _autenticacionRepository = autenticacionRepository,
       _accesoBiometricoRepository = accesoBiometricoRepository,
       _sesionStore = sesionStore;

  final AutenticacionRepository _autenticacionRepository;
  final AccesoBiometricoRepository _accesoBiometricoRepository;
  final SesionStore _sesionStore;
  final Logger _log = Logger('IniciarSesionUseCase');

  /// Mensaje con el que se rechaza a un usuario que no es guardia.
  static const mensajeRolNoPermitido = 'Esta aplicación es solo para guardias';

  Future<Result<UsuarioModel>> ejecutar({
    required String correo,
    required String password,
  }) async {
    final autenticacion = await _autenticacionRepository.autenticar(
      correo: correo.trim(),
      password: password,
    );
    if (autenticacion is Error<void>) {
      return Result.error(autenticacion.error);
    }

    final detalle = await _autenticacionRepository.obtenerUsuarioActual();
    switch (detalle) {
      case Error<UsuarioModel>():
        // Las credenciales eran válidas pero no se pudo leer el detalle:
        // no hay sesión usable, así que se descartan los tokens.
        await _autenticacionRepository.limpiarTokens();
        return Result.error(detalle.error);
      case Ok<UsuarioModel>():
    }

    final usuario = detalle.value;
    if (usuario.rol != RolUsuario.guardia) {
      _log.warning('Rol no permitido en el móvil: ${usuario.rol.valor}');
      await _autenticacionRepository.limpiarTokens();
      await _accesoBiometricoRepository.olvidar();
      return Result.error(const ApiException(mensajeRolNoPermitido));
    }

    // Con la sesión ya válida se recuerda el refresh token: la próxima vez el
    // guardia entra con su huella. Si el dispositivo no tiene biometría
    // utilizable, el repositorio no guarda nada.
    await _accesoBiometricoRepository.recordar();

    _sesionStore.establecerUsuario(usuario);
    return Result.ok(usuario);
  }
}
