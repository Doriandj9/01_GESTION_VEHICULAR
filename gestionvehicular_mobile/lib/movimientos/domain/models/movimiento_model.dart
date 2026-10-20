import 'tipo_movimiento.dart';
import 'ubicacion_model.dart';

/// Movimiento aceptado por la api. Es lo que consume la ui: si la api rechazó
/// el movimiento no llega hasta aquí, el repositorio devuelve `Result.error`.
///
/// `tipo` y `ubicacion` no vienen en la respuesta (`MovimientoResponse` solo
/// trae `registro` y `estado`): los completa el repositorio con lo que se
/// envió, para poder armar el aviso de éxito.
final class MovimientoModel {
  const MovimientoModel({
    required this.registro,
    required this.tipo,
    this.ubicacion,
  });

  /// Fecha y hora en que la api registró el movimiento.
  final DateTime registro;

  /// Tipo registrado (`ENTRADA` o `SALIDA`).
  final TipoMovimiento tipo;

  /// Coordenadas enviadas, o `null` si se registró sin ubicación.
  final UbicacionModel? ubicacion;

  factory MovimientoModel.fromJson(Map<String, dynamic> json) {
    final ubicacion = json['ubicacion'];

    return MovimientoModel(
      registro: DateTime.parse(json['registro'] as String),
      tipo: TipoMovimiento.desdeApi(json['tipo'] as String),
      ubicacion: ubicacion is Map<String, dynamic>
          ? UbicacionModel.fromJson(ubicacion)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'registro': registro.toIso8601String(),
    'tipo': tipo.valor,
    'ubicacion': ubicacion?.toJson(),
  };

  MovimientoModel copyWith({
    DateTime? registro,
    TipoMovimiento? tipo,
    UbicacionModel? ubicacion,
  }) {
    return MovimientoModel(
      registro: registro ?? this.registro,
      tipo: tipo ?? this.tipo,
      ubicacion: ubicacion ?? this.ubicacion,
    );
  }

  @override
  String toString() =>
      'MovimientoModel(registro: $registro, tipo: $tipo, ubicacion: $ubicacion)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovimientoModel &&
        other.registro == registro &&
        other.tipo == tipo &&
        other.ubicacion == ubicacion;
  }

  @override
  int get hashCode => Object.hash(registro, tipo, ubicacion);
}
