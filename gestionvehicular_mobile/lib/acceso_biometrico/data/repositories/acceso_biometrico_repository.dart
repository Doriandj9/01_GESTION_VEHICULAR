import '../../domain/models/credencial_biometrica_model.dart';
import '../services/biometria_service.dart';

/// Contrato del acceso biométrico: la credencial guardada en el dispositivo y
/// la comprobación de identidad. Los casos de uso y la ui dependen de esta
/// interfaz, nunca de sqflite ni de `local_auth`.
abstract class AccesoBiometricoRepository {
  /// Guarda el refresh token vigente para poder volver a entrar con la
  /// biometría. El correo y la caducidad se leen del propio token.
  ///
  /// No hace nada si el dispositivo no tiene biometría utilizable: no tiene
  /// sentido dejar un token guardado que nunca se va a poder usar.
  Future<void> recordar();

  /// Credencial guardada, o `null` si no hay, está ilegible o ya caducó. Una
  /// credencial caducada se borra en la misma llamada.
  Future<CredencialBiometricaModel?> credencialVigente();

  /// Borra la credencial del dispositivo (cierre de sesión, sesión expirada o
  /// refresh token rechazado por el backend).
  Future<void> olvidar();

  /// Qué se puede hacer con la biometría en este dispositivo.
  Future<EstadoBiometria> estadoBiometria();

  /// Comprueba la identidad del guardia con la biometría del dispositivo.
  Future<ResultadoBiometria> comprobarIdentidad();
}
