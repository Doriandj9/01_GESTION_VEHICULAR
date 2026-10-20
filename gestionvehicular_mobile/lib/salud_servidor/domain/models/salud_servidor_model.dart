import 'estado_salud.dart';

/// Salud del backend según `GET /actuator/health`, ya traducida al dominio.
final class SaludServidorModel {
  const SaludServidorModel({required this.estado, this.grupos = const []});

  /// Estado reportado por el actuator.
  final EstadoSalud estado;

  /// Grupos de sondas que declara el actuator (`liveness`, `readiness`).
  final List<String> grupos;

  /// `true` solo si se puede usar la app contra este servidor.
  bool get estaArriba => estado.estaArriba;

  factory SaludServidorModel.fromJson(Map<String, dynamic> json) {
    final grupos = json['grupos'];
    return SaludServidorModel(
      estado: EstadoSalud.desdeApi(json['estado'] as String? ?? ''),
      grupos: grupos is List
          ? grupos.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {'estado': estado.valor, 'grupos': grupos};

  SaludServidorModel copyWith({EstadoSalud? estado, List<String>? grupos}) {
    return SaludServidorModel(
      estado: estado ?? this.estado,
      grupos: grupos ?? this.grupos,
    );
  }

  @override
  String toString() =>
      'SaludServidorModel(estado: ${estado.valor}, grupos: $grupos)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaludServidorModel &&
        other.estado == estado &&
        _mismosGrupos(other.grupos);
  }

  bool _mismosGrupos(List<String> otros) {
    if (otros.length != grupos.length) return false;
    for (var i = 0; i < grupos.length; i++) {
      if (otros[i] != grupos[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(estado, Object.hashAll(grupos));
}
