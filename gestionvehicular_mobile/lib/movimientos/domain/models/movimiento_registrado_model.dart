import 'tipo_movimiento.dart';
import 'ubicacion_model.dart';

/// Un movimiento ya registrado, tal como lo consume la lista de la pantalla.
/// Lo construye el repositorio a partir de `MovimientoRegistradoApiModel`.
final class MovimientoRegistradoModel {
  const MovimientoRegistradoModel({
    required this.fecha,
    required this.tipo,
    this.codVehiculo,
    this.placa,
    this.conductor,
    this.codUsuarioRegistro,
    this.nombreUsuarioRegistro,
    this.ubicacion,
  });

  /// Fecha y hora en que la api registró el movimiento.
  final DateTime fecha;

  /// Tipo registrado (`ENTRADA` o `SALIDA`).
  final TipoMovimiento tipo;

  final int? codVehiculo;
  final String? placa;
  final String? conductor;
  final int? codUsuarioRegistro;
  final String? nombreUsuarioRegistro;

  /// Coordenadas guardadas, o `null` si se registró sin ubicación.
  final UbicacionModel? ubicacion;

  factory MovimientoRegistradoModel.fromJson(Map<String, dynamic> json) {
    final ubicacion = json['ubicacion'];

    return MovimientoRegistradoModel(
      fecha: DateTime.parse(json['fecha'] as String),
      tipo: TipoMovimiento.desdeApi(json['tipo'] as String),
      codVehiculo: (json['codVehiculo'] as num?)?.toInt(),
      placa: json['placa'] as String?,
      conductor: json['conductor'] as String?,
      codUsuarioRegistro: (json['codUsuarioRegistro'] as num?)?.toInt(),
      nombreUsuarioRegistro: json['nombreUsuarioRegistro'] as String?,
      ubicacion: ubicacion is Map<String, dynamic>
          ? UbicacionModel.fromJson(ubicacion)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'fecha': fecha.toIso8601String(),
    'tipo': tipo.valor,
    'codVehiculo': codVehiculo,
    'placa': placa,
    'conductor': conductor,
    'codUsuarioRegistro': codUsuarioRegistro,
    'nombreUsuarioRegistro': nombreUsuarioRegistro,
    'ubicacion': ubicacion?.toJson(),
  };

  MovimientoRegistradoModel copyWith({
    DateTime? fecha,
    TipoMovimiento? tipo,
    int? codVehiculo,
    String? placa,
    String? conductor,
    int? codUsuarioRegistro,
    String? nombreUsuarioRegistro,
    UbicacionModel? ubicacion,
  }) {
    return MovimientoRegistradoModel(
      fecha: fecha ?? this.fecha,
      tipo: tipo ?? this.tipo,
      codVehiculo: codVehiculo ?? this.codVehiculo,
      placa: placa ?? this.placa,
      conductor: conductor ?? this.conductor,
      codUsuarioRegistro: codUsuarioRegistro ?? this.codUsuarioRegistro,
      nombreUsuarioRegistro:
          nombreUsuarioRegistro ?? this.nombreUsuarioRegistro,
      ubicacion: ubicacion ?? this.ubicacion,
    );
  }

  @override
  String toString() =>
      'MovimientoRegistradoModel(fecha: $fecha, tipo: $tipo, placa: $placa, '
      'conductor: $conductor, ubicacion: $ubicacion)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovimientoRegistradoModel &&
        other.fecha == fecha &&
        other.tipo == tipo &&
        other.codVehiculo == codVehiculo &&
        other.placa == placa &&
        other.conductor == conductor &&
        other.codUsuarioRegistro == codUsuarioRegistro &&
        other.nombreUsuarioRegistro == nombreUsuarioRegistro &&
        other.ubicacion == ubicacion;
  }

  @override
  int get hashCode => Object.hash(
    fecha,
    tipo,
    codVehiculo,
    placa,
    conductor,
    codUsuarioRegistro,
    nombreUsuarioRegistro,
    ubicacion,
  );
}
