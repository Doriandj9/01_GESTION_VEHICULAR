/// Rutas de la app. Una sola app, un solo `GoRouter`, rutas absolutas simples:
/// no hay prefijos por ambiente ni rutas por micro app.
abstract final class AppRoutes {
  /// Pantalla de carga mientras se restaura la sesión guardada.
  static const cargando = '/';

  /// El backend no respondió `UP` en `/actuator/health`.
  static const sinServidor = '/sin-servidor';

  /// Inicio de sesión: pantalla inicial cuando no hay sesión.
  static const login = '/login';

  /// Cambio obligatorio de clave (usuario en estado `INICIAL`).
  static const cambiarClave = '/cambiar-clave';

  /// Registro de movimientos: pantalla principal del guardia.
  static const movimientos = '/movimientos';
}
