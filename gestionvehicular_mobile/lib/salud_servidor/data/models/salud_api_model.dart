/// Respuesta de `GET /actuator/health` del backend:
///
/// ```json
/// { "groups": ["liveness", "readiness"], "status": "UP" }
/// ```
///
/// `groups` solo llega cuando el actuator tiene grupos configurados, así que
/// se trata como opcional.
final class SaludApiModel {
  const SaludApiModel({required this.status, this.groups = const []});

  /// Estado que reporta el actuator: `UP`, `DOWN`, `OUT_OF_SERVICE`...
  final String status;

  /// Grupos de sondas declarados (`liveness`, `readiness`).
  final List<String> groups;

  factory SaludApiModel.fromJson(Map<String, dynamic> json) {
    final grupos = json['groups'];
    return SaludApiModel(
      // Un cuerpo sin `status` es tan inservible como no tener respuesta.
      status: json['status'] as String? ?? '',
      groups: grupos is List
          ? grupos.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {'status': status, 'groups': groups};

  SaludApiModel copyWith({String? status, List<String>? groups}) {
    return SaludApiModel(
      status: status ?? this.status,
      groups: groups ?? this.groups,
    );
  }

  @override
  String toString() => 'SaludApiModel(status: $status, groups: $groups)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaludApiModel &&
        other.status == status &&
        _mismosGrupos(other.groups);
  }

  bool _mismosGrupos(List<String> otros) {
    if (otros.length != groups.length) return false;
    for (var i = 0; i < groups.length; i++) {
      if (otros[i] != groups[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(status, Object.hashAll(groups));
}
