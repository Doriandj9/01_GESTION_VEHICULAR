import '../jwt_payload.dart';

/// Credencial que permite volver a entrar con la biometría del dispositivo:
/// el refresh token de la última sesión, con el correo y la caducidad que
/// vienen dentro del propio token.
///
/// No es un dto de la api: se guarda y se lee de la base de datos local.
final class CredencialBiometricaModel {
  const CredencialBiometricaModel({
    required this.correo,
    required this.refreshToken,
    required this.expiraEn,
    required this.guardadaEn,
  });

  /// Correo del dueño de la credencial (claim `sub` del refresh token).
  final String correo;

  /// Refresh token con el que se pedirá un jwt nuevo a `/auth/refresh`.
  final String refreshToken;

  /// Caducidad del refresh token (claim `exp`). Pasada esta fecha hay que
  /// volver a entrar con correo y contraseña.
  final DateTime expiraEn;

  /// Cuándo se guardó la credencial en este dispositivo.
  final DateTime guardadaEn;

  /// Construye la credencial a partir del refresh token: el correo y la
  /// caducidad se leen del propio jwt, no se reciben por fuera.
  ///
  /// Devuelve `null` si el token no se puede decodificar.
  static CredencialBiometricaModel? desdeRefreshToken(String refreshToken) {
    final payload = JwtPayload.desdeToken(refreshToken);
    if (payload == null) return null;
    return CredencialBiometricaModel(
      correo: payload.sub,
      refreshToken: refreshToken,
      expiraEn: payload.exp,
      guardadaEn: DateTime.now().toUtc(),
    );
  }

  factory CredencialBiometricaModel.fromJson(Map<String, dynamic> json) {
    return CredencialBiometricaModel(
      correo: json['correo'] as String,
      refreshToken: json['refreshToken'] as String,
      expiraEn: DateTime.parse(json['expiraEn'] as String),
      guardadaEn: DateTime.parse(json['guardadaEn'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'correo': correo,
    'refreshToken': refreshToken,
    'expiraEn': expiraEn.toIso8601String(),
    'guardadaEn': guardadaEn.toIso8601String(),
  };

  CredencialBiometricaModel copyWith({
    String? correo,
    String? refreshToken,
    DateTime? expiraEn,
    DateTime? guardadaEn,
  }) {
    return CredencialBiometricaModel(
      correo: correo ?? this.correo,
      refreshToken: refreshToken ?? this.refreshToken,
      expiraEn: expiraEn ?? this.expiraEn,
      guardadaEn: guardadaEn ?? this.guardadaEn,
    );
  }

  /// `true` si el refresh token ya no sirve para pedir un jwt nuevo.
  bool get caducada =>
      expiraEn.isBefore(DateTime.now().toUtc().add(JwtPayload.margenSeguridad));

  /// El token nunca se escribe en los logs: solo su longitud.
  @override
  String toString() =>
      'CredencialBiometricaModel(correo: $correo, '
      'refreshToken: ${refreshToken.length} caracteres, '
      'expiraEn: $expiraEn, guardadaEn: $guardadaEn)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CredencialBiometricaModel &&
        other.correo == correo &&
        other.refreshToken == refreshToken &&
        other.expiraEn == expiraEn &&
        other.guardadaEn == guardadaEn;
  }

  @override
  int get hashCode => Object.hash(correo, refreshToken, expiraEn, guardadaEn);
}
