import 'estado_usuario.dart';
import 'rol_usuario.dart';

/// Usuario dueño del jwt, modelo de dominio que consume la ui.
/// Se construye en el repositorio a partir de `UsuarioDetalleApiModel`.
final class UsuarioModel {
  const UsuarioModel({
    required this.codUsuarios,
    required this.nombres,
    required this.correo,
    required this.estado,
    required this.rol,
  });

  final int codUsuarios;
  final String nombres;
  final String correo;
  final EstadoUsuario estado;
  final RolUsuario rol;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      codUsuarios: (json['codUsuarios'] as num).toInt(),
      nombres: json['nombres'] as String,
      correo: json['correo'] as String,
      estado: EstadoUsuario.desdeApi(json['estado'] as String),
      rol: RolUsuario.desdeApi(json['rol'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'codUsuarios': codUsuarios,
    'nombres': nombres,
    'correo': correo,
    'estado': estado.valor,
    'rol': rol.valor,
  };

  UsuarioModel copyWith({
    int? codUsuarios,
    String? nombres,
    String? correo,
    EstadoUsuario? estado,
    RolUsuario? rol,
  }) {
    return UsuarioModel(
      codUsuarios: codUsuarios ?? this.codUsuarios,
      nombres: nombres ?? this.nombres,
      correo: correo ?? this.correo,
      estado: estado ?? this.estado,
      rol: rol ?? this.rol,
    );
  }

  @override
  String toString() =>
      'UsuarioModel(codUsuarios: $codUsuarios, nombres: $nombres, '
      'correo: $correo, estado: $estado, rol: $rol)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsuarioModel &&
        other.codUsuarios == codUsuarios &&
        other.nombres == nombres &&
        other.correo == correo &&
        other.estado == estado &&
        other.rol == rol;
  }

  @override
  int get hashCode => Object.hash(codUsuarios, nombres, correo, estado, rol);
}
