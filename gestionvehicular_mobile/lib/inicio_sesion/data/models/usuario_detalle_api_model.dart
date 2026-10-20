/// Respuesta cruda de `GET /usuarios/detalle`. `estado` y `rol` llegan como
/// texto plano; el repositorio los convierte a los enums del dominio.
final class UsuarioDetalleApiModel {
  const UsuarioDetalleApiModel({
    required this.codUsuarios,
    required this.nombres,
    required this.correo,
    required this.estado,
    required this.rol,
  });

  final int codUsuarios;
  final String nombres;
  final String correo;
  final String estado;
  final String rol;

  factory UsuarioDetalleApiModel.fromJson(Map<String, dynamic> json) {
    return UsuarioDetalleApiModel(
      codUsuarios: (json['codUsuarios'] as num).toInt(),
      nombres: json['nombres'] as String,
      correo: json['correo'] as String,
      estado: json['estado'] as String,
      rol: json['rol'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'codUsuarios': codUsuarios,
    'nombres': nombres,
    'correo': correo,
    'estado': estado,
    'rol': rol,
  };

  UsuarioDetalleApiModel copyWith({
    int? codUsuarios,
    String? nombres,
    String? correo,
    String? estado,
    String? rol,
  }) {
    return UsuarioDetalleApiModel(
      codUsuarios: codUsuarios ?? this.codUsuarios,
      nombres: nombres ?? this.nombres,
      correo: correo ?? this.correo,
      estado: estado ?? this.estado,
      rol: rol ?? this.rol,
    );
  }

  @override
  String toString() =>
      'UsuarioDetalleApiModel(codUsuarios: $codUsuarios, nombres: $nombres, '
      'correo: $correo, estado: $estado, rol: $rol)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsuarioDetalleApiModel &&
        other.codUsuarios == codUsuarios &&
        other.nombres == nombres &&
        other.correo == correo &&
        other.estado == estado &&
        other.rol == rol;
  }

  @override
  int get hashCode => Object.hash(codUsuarios, nombres, correo, estado, rol);
}
