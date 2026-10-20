import '../../../core/utils/result.dart';
import '../../../domain/models/sesion/usuario_model.dart';

/// Contrato de acceso a la autenticación. La ui y los casos de uso dependen de
/// esta interfaz, nunca de la implementación ni del `ApiClient`.
abstract class AutenticacionRepository {
  /// `POST /auth`: valida credenciales y guarda el par de tokens.
  Future<Result<void>> autenticar({
    required String correo,
    required String password,
  });

  /// `POST /auth/refresh`: canjea un refresh token por un par nuevo y lo
  /// guarda. La usa el acceso biométrico, que entra sin contraseña.
  ///
  /// Ojo: el backend revoca los tokens anteriores en cada refresco, así que el
  /// token que se envía deja de servir en cuanto esta llamada tiene éxito.
  Future<Result<void>> refrescarSesion(String refreshToken);

  /// `GET /usuarios/detalle`: usuario dueño del jwt guardado.
  Future<Result<UsuarioModel>> obtenerUsuarioActual();

  /// `POST /auth/change-password`: cambia la clave y **reemplaza** los tokens
  /// guardados, porque la api devuelve un par nuevo.
  Future<Result<void>> cambiarClave({
    required String correo,
    required String oldPassword,
    required String newPassword,
  });

  /// `POST /auth/logout`: avisa a la api y limpia los tokens locales pase lo
  /// que pase con la llamada.
  Future<Result<void>> cerrarSesion();

  /// `true` si hay un jwt guardado en el dispositivo (no valida su vigencia).
  Future<bool> haySesionGuardada();

  /// Borra los tokens del dispositivo sin llamar a la api. Se usa cuando la
  /// sesión expira o cuando se rechaza al usuario por su rol.
  Future<void> limpiarTokens();
}
