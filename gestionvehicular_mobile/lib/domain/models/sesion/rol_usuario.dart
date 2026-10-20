/// Roles que devuelve la api en `GET /usuarios/detalle`.
/// La app móvil solo admite `guardia`.
enum RolUsuario {
  administrador('ADMINISTRADOR'),
  guardia('GUARDIA');

  const RolUsuario(this.valor);

  /// Texto tal como lo envía la api.
  final String valor;

  /// Etiqueta para mostrar en la ui.
  String get etiqueta => switch (this) {
    RolUsuario.administrador => 'Administrador',
    RolUsuario.guardia => 'Guardia',
  };

  /// Convierte el texto plano de la api al enum. Lanza si el rol es desconocido.
  static RolUsuario desdeApi(String valor) {
    return RolUsuario.values.firstWhere(
      (rol) => rol.valor == valor.toUpperCase(),
      orElse: () => throw ArgumentError('Rol de usuario desconocido: $valor'),
    );
  }
}
