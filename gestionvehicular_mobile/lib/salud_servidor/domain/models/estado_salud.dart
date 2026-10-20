/// Estados que reporta el actuator de Spring Boot en `status`.
enum EstadoSalud {
  /// El servidor y sus componentes responden.
  up('UP', 'disponible'),

  /// El servidor responde pero algún componente está caído (suele venir con
  /// un 503), por ejemplo la base de datos.
  down('DOWN', 'con fallas'),

  /// El servidor se declaró fuera de servicio a propósito.
  fueraDeServicio('OUT_OF_SERVICE', 'fuera de servicio'),

  /// El actuator no sabe decir cómo está.
  desconocido('UNKNOWN', 'en estado desconocido');

  const EstadoSalud(this.valor, this.etiqueta);

  /// Texto tal como lo manda la api.
  final String valor;

  /// Texto para mostrarle al guardia.
  final String etiqueta;

  /// `true` solo si el servidor está operativo.
  bool get estaArriba => this == EstadoSalud.up;

  /// Traduce el `status` de la api. Cualquier valor no previsto se trata como
  /// [EstadoSalud.desconocido]: un estado que no se reconoce no se da por
  /// bueno.
  static EstadoSalud desdeApi(String valor) {
    final normalizado = valor.trim().toUpperCase();
    return EstadoSalud.values.firstWhere(
      (estado) => estado.valor == normalizado,
      orElse: () => EstadoSalud.desconocido,
    );
  }
}
