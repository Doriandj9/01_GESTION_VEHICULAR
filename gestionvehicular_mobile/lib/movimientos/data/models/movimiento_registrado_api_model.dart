/// Respuesta cruda de `GET /movimientos/usuario`
/// (`MovimientoResponseRegistrado`). Es un movimiento ya registrado, con los
/// datos del vehículo y de quien lo registró.
///
/// Todos los campos llegan opcionales en el OpenAPI, así que se tratan como
/// anulables y es el repositorio el que decide qué es imprescindible.
final class MovimientoRegistradoApiModel {
  const MovimientoRegistradoApiModel({
    this.codUsuarioRegistro,
    this.nombreUsuarioRegistro,
    this.latitudRegistro,
    this.longitudRegistro,
    this.fechaRegistro,
    this.tipoMovimiento,
    this.codVehiculo,
    this.placa,
    this.conductor,
  });

  final int? codUsuarioRegistro;
  final String? nombreUsuarioRegistro;
  final double? latitudRegistro;
  final double? longitudRegistro;
  final String? fechaRegistro;
  final String? tipoMovimiento;
  final int? codVehiculo;
  final String? placa;
  final String? conductor;

  factory MovimientoRegistradoApiModel.fromJson(Map<String, dynamic> json) {
    return MovimientoRegistradoApiModel(
      codUsuarioRegistro: (json['codUsuarioRegistro'] as num?)?.toInt(),
      nombreUsuarioRegistro: json['nombreUsuarioRegistro'] as String?,
      latitudRegistro: (json['latitudRegistro'] as num?)?.toDouble(),
      longitudRegistro: (json['longitudRegistro'] as num?)?.toDouble(),
      fechaRegistro: json['fechaRegistro'] as String?,
      tipoMovimiento: json['tipoMovimiento'] as String?,
      codVehiculo: (json['codVehiculo'] as num?)?.toInt(),
      placa: json['placa'] as String?,
      conductor: json['conductor'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'codUsuarioRegistro': codUsuarioRegistro,
    'nombreUsuarioRegistro': nombreUsuarioRegistro,
    'latitudRegistro': latitudRegistro,
    'longitudRegistro': longitudRegistro,
    'fechaRegistro': fechaRegistro,
    'tipoMovimiento': tipoMovimiento,
    'codVehiculo': codVehiculo,
    'placa': placa,
    'conductor': conductor,
  };

  MovimientoRegistradoApiModel copyWith({
    int? codUsuarioRegistro,
    String? nombreUsuarioRegistro,
    double? latitudRegistro,
    double? longitudRegistro,
    String? fechaRegistro,
    String? tipoMovimiento,
    int? codVehiculo,
    String? placa,
    String? conductor,
  }) {
    return MovimientoRegistradoApiModel(
      codUsuarioRegistro: codUsuarioRegistro ?? this.codUsuarioRegistro,
      nombreUsuarioRegistro:
          nombreUsuarioRegistro ?? this.nombreUsuarioRegistro,
      latitudRegistro: latitudRegistro ?? this.latitudRegistro,
      longitudRegistro: longitudRegistro ?? this.longitudRegistro,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      tipoMovimiento: tipoMovimiento ?? this.tipoMovimiento,
      codVehiculo: codVehiculo ?? this.codVehiculo,
      placa: placa ?? this.placa,
      conductor: conductor ?? this.conductor,
    );
  }

  @override
  String toString() =>
      'MovimientoRegistradoApiModel(codUsuarioRegistro: $codUsuarioRegistro, '
      'fechaRegistro: $fechaRegistro, tipoMovimiento: $tipoMovimiento, '
      'placa: $placa, conductor: $conductor)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovimientoRegistradoApiModel &&
        other.codUsuarioRegistro == codUsuarioRegistro &&
        other.nombreUsuarioRegistro == nombreUsuarioRegistro &&
        other.latitudRegistro == latitudRegistro &&
        other.longitudRegistro == longitudRegistro &&
        other.fechaRegistro == fechaRegistro &&
        other.tipoMovimiento == tipoMovimiento &&
        other.codVehiculo == codVehiculo &&
        other.placa == placa &&
        other.conductor == conductor;
  }

  @override
  int get hashCode => Object.hash(
    codUsuarioRegistro,
    nombreUsuarioRegistro,
    latitudRegistro,
    longitudRegistro,
    fechaRegistro,
    tipoMovimiento,
    codVehiculo,
    placa,
    conductor,
  );
}
