import 'dart:convert';

/// Carga útil de un jwt, leída sin verificar la firma.
///
/// Solo se usa para saber **a quién** pertenece el refresh token guardado y
/// **cuándo caduca**. La validación de verdad la hace el backend: aquí se lee
/// para no gastar una llamada a `/auth/refresh` que ya se sabe que va a fallar.
///
/// El backend firma los tokens en `JwtService.buildToken`, que pone siempre
/// `sub` (el correo), `iat` (emisión) y `exp` (caducidad).
final class JwtPayload {
  const JwtPayload({required this.sub, required this.iat, required this.exp});

  /// Correo del usuario dueño del token (claim `sub`).
  final String sub;

  /// Momento de emisión (claim `iat`).
  final DateTime iat;

  /// Momento de caducidad (claim `exp`).
  final DateTime exp;

  /// Margen con el que se considera caducado un token que está por caducar:
  /// evita refrescar con un token que expira mientras viaja la petición.
  static const margenSeguridad = Duration(minutes: 1);

  /// Decodifica la carga útil de [token]. Devuelve `null` si el token no tiene
  /// tres partes, si el base64url está corrupto o si falta `sub` o `exp`.
  static JwtPayload? desdeToken(String token) {
    final partes = token.split('.');
    if (partes.length != 3) return null;
    try {
      final json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      ) as Map<String, dynamic>;
      final sub = json['sub'];
      final exp = json['exp'];
      final iat = json['iat'];
      if (sub is! String || sub.isEmpty || exp is! int) return null;
      return JwtPayload(
        sub: sub,
        // `iat` es informativo: si no viene se asume el momento de la lectura.
        iat: _desdeEpoch(iat is int ? iat : null) ?? DateTime.now().toUtc(),
        exp: _desdeEpoch(exp)!,
      );
    } on Exception {
      // Base64 corrupto, json inválido o claims con otro tipo: no hay token
      // usable, y eso se resuelve volviendo a entrar con la contraseña.
      return null;
    }
  }

  /// `true` si el token ya caducó o caduca dentro del [margenSeguridad].
  bool get caducado =>
      exp.isBefore(DateTime.now().toUtc().add(margenSeguridad));

  /// Tiempo que le queda de vida, o `Duration.zero` si ya caducó.
  Duration get vigenciaRestante {
    final restante = exp.difference(DateTime.now().toUtc());
    return restante.isNegative ? Duration.zero : restante;
  }

  /// Los claims `iat` y `exp` del jwt van en **segundos**, no en milisegundos.
  static DateTime? _desdeEpoch(int? segundos) => segundos == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(segundos * 1000, isUtc: true);

  @override
  String toString() => 'JwtPayload(sub: $sub, iat: $iat, exp: $exp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JwtPayload &&
        other.sub == sub &&
        other.iat == iat &&
        other.exp == exp;
  }

  @override
  int get hashCode => Object.hash(sub, iat, exp);
}
