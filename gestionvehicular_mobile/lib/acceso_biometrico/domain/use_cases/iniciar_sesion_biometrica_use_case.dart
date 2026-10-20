import 'package:logging/logging.dart';

import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../domain/models/sesion/rol_usuario.dart';
import '../../../domain/models/sesion/usuario_model.dart';
import '../../../domain/stores/sesion_store.dart';
import '../../../inicio_sesion/data/repositories/autenticacion_repository.dart';
import '../../../inicio_sesion/domain/use_cases/iniciar_sesion_use_case.dart';
import '../../data/repositories/acceso_biometrico_repository.dart';
import '../../data/services/biometria_service.dart';

/// Caso de uso del ingreso con biometría. Es un caso de uso porque encadena
/// varios pasos de dos repositorios distintos:
///
/// 1. comprobar la identidad con la huella o el rostro del dispositivo;
/// 2. leer la credencial guardada (si caducó, se borra y se exige contraseña);
/// 3. `POST /auth/refresh` para canjear el refresh token por un par nuevo;
/// 4. **volver a recordar** el refresh token nuevo, porque el backend revoca
///    el anterior en cada refresco;
/// 5. `GET /usuarios/detalle`, rechazo de los roles distintos de `GUARDIA` y
///    publicación del usuario en el [SesionStore].
class IniciarSesionBiometricaUseCase {
  IniciarSesionBiometricaUseCase({
    required AccesoBiometricoRepository accesoBiometricoRepository,
    required AutenticacionRepository autenticacionRepository,
    required SesionStore sesionStore,
  }) : _accesoBiometricoRepository = accesoBiometricoRepository,
       _autenticacionRepository = autenticacionRepository,
       _sesionStore = sesionStore;

  /// La credencial caducó o nunca se guardó: toca la contraseña.
  static const mensajeSinCredencial =
      'Su acceso rápido caducó. Ingrese con su correo y su contraseña.';

  /// La huella o el rostro no coincidieron.
  static const mensajeNoReconocido = 'No se reconoció su huella ni su rostro.';

  /// Demasiados intentos fallidos: lo bloquea el sistema, no la app.
  static const mensajeBloqueado =
      'El dispositivo bloqueó la biometría. Ingrese con su contraseña.';

  /// El dispositivo no puede usar biometría (sin sensor o sin registro).
  static const mensajeNoDisponible =
      'Este dispositivo no tiene biometría disponible.';

  /// El refresh token ya no lo acepta el backend (revocado o sesión abierta en
  /// otro dispositivo): hay que volver a autenticarse con la contraseña.
  static const mensajeRefrescoRechazado =
      'Su acceso rápido ya no es válido. Ingrese con su correo y su contraseña.';

  final AccesoBiometricoRepository _accesoBiometricoRepository;
  final AutenticacionRepository _autenticacionRepository;
  final SesionStore _sesionStore;
  final Logger _log = Logger('IniciarSesionBiometricaUseCase');

  Future<Result<UsuarioModel>> ejecutar() async {
    // Se mira primero si hay credencial: así no se molesta al guardia con el
    // diálogo de la huella para después decirle que igual necesita la clave.
    final credencial = await _accesoBiometricoRepository.credencialVigente();
    if (credencial == null) {
      return Result.error(const ApiException(mensajeSinCredencial));
    }

    final identidad = await _accesoBiometricoRepository.comprobarIdentidad();
    if (!identidad.fueAutorizado) {
      _log.info('Biometría no autorizada: ${identidad.name}');
      return Result.error(ApiException(_mensajeDe(identidad)));
    }

    final refresco = await _autenticacionRepository.refrescarSesion(
      credencial.refreshToken,
    );
    if (refresco is Error<void>) {
      // El backend rechazó el refresh token: ya no sirve para nada, así que se
      // olvida en lugar de dejar un acceso biométrico roto en la pantalla.
      _log.warning('El refresco biométrico falló: ${refresco.error}');
      await _accesoBiometricoRepository.olvidar();
      return Result.error(const ApiException(mensajeRefrescoRechazado));
    }

    // El refresco devolvió un refresh token nuevo y revocó el que se usó: si
    // no se guarda el nuevo, el próximo ingreso biométrico fallaría.
    await _accesoBiometricoRepository.recordar();

    final detalle = await _autenticacionRepository.obtenerUsuarioActual();
    switch (detalle) {
      case Error<UsuarioModel>():
        await _autenticacionRepository.limpiarTokens();
        return Result.error(detalle.error);
      case Ok<UsuarioModel>():
    }

    final usuario = detalle.value;
    if (usuario.rol != RolUsuario.guardia) {
      _log.warning('Rol no permitido en el móvil: ${usuario.rol.valor}');
      await _autenticacionRepository.limpiarTokens();
      await _accesoBiometricoRepository.olvidar();
      return Result.error(
        const ApiException(IniciarSesionUseCase.mensajeRolNoPermitido),
      );
    }

    _sesionStore.establecerUsuario(usuario);
    _log.info('Sesión iniciada con biometría: ${usuario.correo}');
    return Result.ok(usuario);
  }

  String _mensajeDe(ResultadoBiometria resultado) => switch (resultado) {
    ResultadoBiometria.rechazado => mensajeNoReconocido,
    ResultadoBiometria.bloqueado => mensajeBloqueado,
    ResultadoBiometria.noDisponible => mensajeNoDisponible,
    // Cancelar es una decisión del guardia, no un fallo: se avisa en seco.
    ResultadoBiometria.cancelado => 'Ingreso con biometría cancelado.',
    ResultadoBiometria.error => ApiErrors.mensajeGenerico,
    ResultadoBiometria.autorizado => ApiErrors.mensajeGenerico,
  };
}
