import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

import 'biometria_service.dart';

/// Implementación de [BiometriaService] sobre `local_auth`. Es el **único**
/// archivo del proyecto que importa ese paquete.
class BiometriaServiceImpl implements BiometriaService {
  BiometriaServiceImpl({LocalAuthentication? autenticacionLocal})
    : _autenticacionLocal = autenticacionLocal ?? LocalAuthentication();

  final LocalAuthentication _autenticacionLocal;
  final Logger _log = Logger('BiometriaServiceImpl');

  @override
  Future<EstadoBiometria> consultarEstado() async {
    try {
      if (!await _autenticacionLocal.canCheckBiometrics) {
        return EstadoBiometria.sinHardware;
      }
      // Tener sensor no basta: si el guardia no registró ninguna huella ni
      // rostro, el diálogo del sistema fallaría al abrirse.
      final registradas = await _autenticacionLocal.getAvailableBiometrics();
      if (registradas.isEmpty) return EstadoBiometria.sinRegistro;
      _log.info('Biometría disponible: ${registradas.map((b) => b.name)}');
      return EstadoBiometria.disponible;
    } on LocalAuthException catch (e) {
      _log.warning('No se pudo consultar la biometría: ${e.code.name}');
      return _estadoDesdeCodigo(e.code);
    } on Exception catch (e) {
      _log.warning('No se pudo consultar la biometría: $e');
      return EstadoBiometria.noDisponible;
    }
  }

  @override
  Future<ResultadoBiometria> autenticar({required String motivo}) async {
    try {
      // `biometricOnly` deja fuera el pin y el patrón del teléfono: aquí se
      // comprueba a la **persona**, no que tenga el dispositivo desbloqueado.
      final autorizado = await _autenticacionLocal.authenticate(
        localizedReason: motivo,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return autorizado
          ? ResultadoBiometria.autorizado
          : ResultadoBiometria.rechazado;
    } on LocalAuthException catch (e) {
      _log.warning('Fallo la biometría: ${e.code.name} (${e.description})');
      return _resultadoDesdeCodigo(e.code);
    } on Exception catch (e) {
      _log.warning('Fallo la biometría: $e');
      return ResultadoBiometria.error;
    }
  }

  /// `LocalAuthExceptionCode` puede crecer sin que sea un cambio de ruptura,
  /// así que las dos traducciones llevan siempre un caso por defecto.
  EstadoBiometria _estadoDesdeCodigo(LocalAuthExceptionCode codigo) {
    return switch (codigo) {
      LocalAuthExceptionCode.noBiometricHardware => EstadoBiometria.sinHardware,
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noCredentialsSet => EstadoBiometria.sinRegistro,
      _ => EstadoBiometria.noDisponible,
    };
  }

  ResultadoBiometria _resultadoDesdeCodigo(LocalAuthExceptionCode codigo) {
    return switch (codigo) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.timeout ||
      LocalAuthExceptionCode.userRequestedFallback =>
        ResultadoBiometria.cancelado,
      LocalAuthExceptionCode.biometricLockout ||
      LocalAuthExceptionCode.temporaryLockout => ResultadoBiometria.bloqueado,
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noCredentialsSet ||
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
        ResultadoBiometria.noDisponible,
      _ => ResultadoBiometria.error,
    };
  }
}
