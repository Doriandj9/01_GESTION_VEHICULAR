/// Qué puede hacer el dispositivo con la biometría.
enum EstadoBiometria {
  /// Hay sensor y al menos una huella o rostro registrado: se puede usar.
  disponible,

  /// Hay sensor pero el usuario no registró ninguna huella ni rostro.
  sinRegistro,

  /// El dispositivo no tiene sensor biométrico.
  sinHardware,

  /// El sensor existe pero está bloqueado o inaccesible ahora mismo.
  noDisponible;

  /// `true` si se le puede ofrecer el acceso biométrico al guardia.
  bool get permiteAutenticar => this == EstadoBiometria.disponible;
}

/// Desenlace de un intento de autenticación biométrica.
enum ResultadoBiometria {
  /// La huella o el rostro coincidieron.
  autorizado,

  /// La huella o el rostro no coincidieron.
  rechazado,

  /// El guardia cerró el diálogo del sistema.
  cancelado,

  /// Demasiados intentos fallidos: el sensor quedó bloqueado por el sistema.
  bloqueado,

  /// No se puede usar la biometría en este dispositivo.
  noDisponible,

  /// Cualquier otro fallo del sistema operativo.
  error;

  /// `true` solo cuando la identidad quedó comprobada.
  bool get fueAutorizado => this == ResultadoBiometria.autorizado;
}

/// Acceso a la biometría del dispositivo. La ui y los casos de uso dependen de
/// esta interfaz: `local_auth` se importa únicamente en la implementación.
abstract class BiometriaService {
  /// Qué se puede hacer con la biometría en este dispositivo.
  Future<EstadoBiometria> consultarEstado();

  /// Abre el diálogo del sistema para comprobar la identidad. [motivo] es el
  /// texto que el sistema muestra al guardia.
  Future<ResultadoBiometria> autenticar({required String motivo});
}
