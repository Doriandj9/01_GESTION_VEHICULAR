/// Tipo de movimiento que registra el guardia, tal como lo espera
/// `POST /movimientos` en el campo `tipo`.
enum TipoMovimiento {
  entrada('ENTRADA'),
  salida('SALIDA');

  const TipoMovimiento(this.valor);

  /// Texto tal como lo envía y lo devuelve la api.
  final String valor;

  /// Etiqueta para mostrar en la ui.
  String get etiqueta => switch (this) {
    TipoMovimiento.entrada => 'Entrada',
    TipoMovimiento.salida => 'Salida',
  };

  /// Convierte el texto plano de la api al enum. Lanza si el tipo es desconocido.
  static TipoMovimiento desdeApi(String valor) {
    return TipoMovimiento.values.firstWhere(
      (tipo) => tipo.valor == valor.toUpperCase(),
      orElse: () =>
          throw ArgumentError('Tipo de movimiento desconocido: $valor'),
    );
  }
}
