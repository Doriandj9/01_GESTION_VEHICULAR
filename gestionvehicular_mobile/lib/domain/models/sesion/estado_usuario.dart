/// Estados de un usuario que devuelve la api en `GET /usuarios/detalle`.
/// `inicial` obliga a cambiar la clave antes de usar la app.
enum EstadoUsuario {
  activo('ACTIVO'),
  inactivo('INACTIVO'),
  inicial('INICIAL');

  const EstadoUsuario(this.valor);

  /// Texto tal como lo envía la api.
  final String valor;

  /// `true` cuando el usuario todavía usa la clave asignada y debe cambiarla.
  bool get requiereCambioDeClave => this == EstadoUsuario.inicial;

  /// Convierte el texto plano de la api al enum. Lanza si el estado es desconocido.
  static EstadoUsuario desdeApi(String valor) {
    return EstadoUsuario.values.firstWhere(
      (estado) => estado.valor == valor.toUpperCase(),
      orElse: () =>
          throw ArgumentError('Estado de usuario desconocido: $valor'),
    );
  }
}
