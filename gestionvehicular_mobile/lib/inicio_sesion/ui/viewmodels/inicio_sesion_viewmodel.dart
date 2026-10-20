import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../acceso_biometrico/data/repositories/acceso_biometrico_repository.dart';
import '../../../acceso_biometrico/data/services/biometria_service.dart';
import '../../../acceso_biometrico/domain/models/credencial_biometrica_model.dart';
import '../../../acceso_biometrico/domain/use_cases/iniciar_sesion_biometrica_use_case.dart';
import '../../../core/utils/command.dart';
import '../../../core/utils/result.dart';
import '../../../domain/models/sesion/usuario_model.dart';
import '../../domain/use_cases/iniciar_sesion_use_case.dart';

/// Viewmodel de la pantalla de inicio de sesión. Está ligado a una sola vista
/// y se crea en el `builder` de la ruta, nunca en `provider`.
///
/// Atiende los dos caminos de ingreso de esa pantalla: correo y contraseña, y
/// biometría con el refresh token guardado en el dispositivo.
class InicioSesionViewmodel extends ChangeNotifier {
  InicioSesionViewmodel({
    required IniciarSesionUseCase iniciarSesionUseCase,
    required IniciarSesionBiometricaUseCase iniciarSesionBiometricaUseCase,
    required AccesoBiometricoRepository accesoBiometricoRepository,
  }) : _iniciarSesionUseCase = iniciarSesionUseCase,
       _iniciarSesionBiometricaUseCase = iniciarSesionBiometricaUseCase,
       _accesoBiometricoRepository = accesoBiometricoRepository {
    iniciarSesion = Command1<UsuarioModel, (String, String)>(_iniciarSesion);
    iniciarSesionBiometrica = Command0<UsuarioModel>(_iniciarSesionBiometrica);
    // Al abrir el login se mira si este dispositivo recuerda a un guardia:
    // de eso depende que se pinte el icono de la huella.
    revisarBiometria = Command0<CredencialBiometricaModel?>(_revisarBiometria)
      ..execute();
  }

  final IniciarSesionUseCase _iniciarSesionUseCase;
  final IniciarSesionBiometricaUseCase _iniciarSesionBiometricaUseCase;
  final AccesoBiometricoRepository _accesoBiometricoRepository;
  final Logger _log = Logger('InicioSesionViewmodel');

  /// Comando del login: recibe (correo, contraseña).
  late final Command1<UsuarioModel, (String, String)> iniciarSesion;

  /// Comando del ingreso con huella o rostro.
  late final Command0<UsuarioModel> iniciarSesionBiometrica;

  /// Comando que averigua si se puede ofrecer el acceso biométrico.
  late final Command0<CredencialBiometricaModel?> revisarBiometria;

  bool _claveVisible = false;
  EstadoBiometria? _estadoBiometria;
  CredencialBiometricaModel? _credencial;

  /// `true` cuando la contraseña se muestra en claro.
  bool get claveVisible => _claveVisible;

  /// Estado de la biometría del dispositivo, o `null` mientras se consulta.
  EstadoBiometria? get estadoBiometria => _estadoBiometria;

  /// Credencial guardada en el dispositivo, o `null` si no hay ninguna vigente.
  CredencialBiometricaModel? get credencial => _credencial;

  /// `true` solo si hay biometría utilizable **y** una credencial vigente: sin
  /// las dos cosas no se pinta el icono de la huella.
  bool get puedeUsarBiometria =>
      (_estadoBiometria?.permiteAutenticar ?? false) && _credencial != null;

  /// Alterna la visibilidad de la contraseña.
  void alternarVisibilidadClave() {
    _claveVisible = !_claveVisible;
    notifyListeners();
  }

  Future<Result<UsuarioModel>> _iniciarSesion(
    (String, String) credenciales,
  ) async {
    final (correo, password) = credenciales;
    final resultado = await _iniciarSesionUseCase.ejecutar(
      correo: correo,
      password: password,
    );
    if (resultado is Error<UsuarioModel>) {
      _log.warning('Error al iniciar sesión: ${resultado.error}');
    }
    return resultado;
  }

  Future<Result<UsuarioModel>> _iniciarSesionBiometrica() async {
    final resultado = await _iniciarSesionBiometricaUseCase.ejecutar();
    if (resultado is Error<UsuarioModel>) {
      _log.warning('Error al ingresar con biometría: ${resultado.error}');
      // El caso de uso pudo borrar la credencial (caducada o rechazada por el
      // backend): se revisa de nuevo para que el icono desaparezca si ya no
      // sirve de nada.
      await revisarBiometria.execute();
    }
    return resultado;
  }

  Future<Result<CredencialBiometricaModel?>> _revisarBiometria() async {
    _estadoBiometria = await _accesoBiometricoRepository.estadoBiometria();
    _credencial = _estadoBiometria!.permiteAutenticar
        ? await _accesoBiometricoRepository.credencialVigente()
        : null;
    _log.info(
      'Biometría ${_estadoBiometria!.name}; '
      'credencial: ${_credencial?.correo ?? 'ninguna'}',
    );
    notifyListeners();
    return Result.ok(_credencial);
  }
}
