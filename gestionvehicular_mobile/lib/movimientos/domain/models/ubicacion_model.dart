/// Coordenadas desde donde se registra un movimiento. Son opcionales para la
/// api: si el guardia niega el permiso, el movimiento se registra sin ellas.
final class UbicacionModel {
  const UbicacionModel({required this.latitud, required this.longitud});

  final double latitud;
  final double longitud;

  factory UbicacionModel.fromJson(Map<String, dynamic> json) {
    return UbicacionModel(
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'latitud': latitud, 'longitud': longitud};

  UbicacionModel copyWith({double? latitud, double? longitud}) {
    return UbicacionModel(
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
    );
  }

  @override
  String toString() => 'UbicacionModel(latitud: $latitud, longitud: $longitud)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UbicacionModel &&
        other.latitud == latitud &&
        other.longitud == longitud;
  }

  @override
  int get hashCode => Object.hash(latitud, longitud);
}
