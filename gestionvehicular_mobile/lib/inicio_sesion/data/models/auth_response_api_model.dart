/// Respuesta de `POST /auth`, `POST /auth/refresh` y
/// `POST /auth/change-password`. `jwtExpired` es la duración del jwt en
/// milisegundos (~86400000 = 24 h), no una fecha epoch.
final class AuthResponseApiModel {
  const AuthResponseApiModel({
    required this.jwt,
    required this.refreshToken,
    required this.jwtExpired,
  });

  final String jwt;
  final String refreshToken;
  final int jwtExpired;

  factory AuthResponseApiModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseApiModel(
      jwt: json['jwt'] as String,
      refreshToken: json['refreshToken'] as String,
      jwtExpired: (json['jwtExpired'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'jwt': jwt,
    'refreshToken': refreshToken,
    'jwtExpired': jwtExpired,
  };

  AuthResponseApiModel copyWith({
    String? jwt,
    String? refreshToken,
    int? jwtExpired,
  }) {
    return AuthResponseApiModel(
      jwt: jwt ?? this.jwt,
      refreshToken: refreshToken ?? this.refreshToken,
      jwtExpired: jwtExpired ?? this.jwtExpired,
    );
  }

  @override
  String toString() =>
      'AuthResponseApiModel(jwt: ***, refreshToken: ***, jwtExpired: $jwtExpired)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResponseApiModel &&
        other.jwt == jwt &&
        other.refreshToken == refreshToken &&
        other.jwtExpired == jwtExpired;
  }

  @override
  int get hashCode => Object.hash(jwt, refreshToken, jwtExpired);
}
