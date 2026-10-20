/// Respuesta cruda de `POST /movimientos` (`MovimientoResponse`):
/// `{ registro, estado }`, con `registro` como `date-time` y `estado` como
/// `SUCCESS` | `ERROR` en texto plano.
final class MovimientoApiModel {
  const MovimientoApiModel({required this.registro, required this.estado});

  final String registro;
  final String estado;

  factory MovimientoApiModel.fromJson(Map<String, dynamic> json) {
    return MovimientoApiModel(
      registro: json['registro'] as String,
      estado: json['estado'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'registro': registro, 'estado': estado};

  MovimientoApiModel copyWith({String? registro, String? estado}) {
    return MovimientoApiModel(
      registro: registro ?? this.registro,
      estado: estado ?? this.estado,
    );
  }

  @override
  String toString() =>
      'MovimientoApiModel(registro: $registro, estado: $estado)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovimientoApiModel &&
        other.registro == registro &&
        other.estado == estado;
  }

  @override
  int get hashCode => Object.hash(registro, estado);
}
