/// Estado que devuelve `POST /movimientos` en el campo `estado`.
///
/// Ojo: un movimiento rechazado llega como **200 con `estado: ERROR`**, no como
/// error http. El repositorio es el que lo convierte en `Result.error`.
enum EstadoMovimiento {
  exito('SUCCESS'),
  error('ERROR');

  const EstadoMovimiento(this.valor);

  /// Texto tal como lo devuelve la api.
  final String valor;

  /// `true` cuando la api aceptó el movimiento.
  bool get fueAceptado => this == EstadoMovimiento.exito;

  /// Convierte el texto plano de la api al enum. Lanza si el estado es desconocido.
  static EstadoMovimiento desdeApi(String valor) {
    return EstadoMovimiento.values.firstWhere(
      (estado) => estado.valor == valor.toUpperCase(),
      orElse: () =>
          throw ArgumentError('Estado de movimiento desconocido: $valor'),
    );
  }
}
