/// Validaciones del formulario de inicio de sesión, hechas en el front antes
/// de llamar a la api. Viven en el dominio para poder probarse sin la ui.
abstract final class ValidacionesInicioSesion {
  /// La api exige formato email en `correo`.
  static final _patronCorreo = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Devuelve el mensaje de error del correo, o `null` si es válido.
  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Ingrese su correo';
    if (!_patronCorreo.hasMatch(texto)) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  /// Devuelve el mensaje de error de la clave, o `null` si es válida.
  /// Aquí solo se comprueba que no esté vacía: la fortaleza se valida en el
  /// cambio de clave, no en el login.
  static String? password(String? valor) {
    if ((valor ?? '').isEmpty) return 'Ingrese su contraseña';
    return null;
  }
}
