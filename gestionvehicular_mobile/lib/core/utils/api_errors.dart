import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Error de la api ya normalizado al formato que la ui sabe mostrar:
/// un `message` obligatorio y, opcionalmente, los pares campo -> mensaje
/// de `errors` (validaciones del backend).
final class ApiException implements Exception {
  const ApiException(this.message, {this.errors = const {}});

  /// Mensaje principal, siempre se muestra.
  final String message;

  /// Validaciones por campo. Vacío cuando la api no devolvió ninguna.
  final Map<String, String> errors;

  @override
  String toString() => 'ApiException(message: $message, errors: $errors)';
}

/// Helper único que traduce cualquier fallo (respuesta http con error,
/// excepción de red o excepción propia del front) a un [ApiException].
abstract final class ApiErrors {
  /// Mensaje de reserva cuando la api no respondió el formato esperado
  /// (por ejemplo el 403 que llega sin `message` ni `errors`).
  static const mensajeGenerico =
      'No se pudo completar la operación. Intente nuevamente.';

  /// Mensaje cuando no hay red o el servidor no responde.
  static const mensajeSinConexion = 'Sin conexión con el servidor';

  /// Mensaje cuando la sesión ya no es válida y no se pudo renovar.
  static const mensajeSesionExpirada =
      'La sesión expiró. Inicie sesión nuevamente.';

  /// Construye el error a partir de una respuesta http con código de error.
  /// El backend responde `{ timestamp, status, error, errors, message, path }`,
  /// pero no siempre trae `message` ni `errors`.
  static ApiException desdeRespuesta(http.Response respuesta) {
    try {
      final cuerpo = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (cuerpo is Map<String, dynamic>) {
        final mensaje = cuerpo['message'] as String?;
        final crudos = cuerpo['errors'];
        final validaciones = <String, String>{};
        if (crudos is Map) {
          for (final entrada in crudos.entries) {
            validaciones['${entrada.key}'] = '${entrada.value}';
          }
        }
        return ApiException(
          (mensaje != null && mensaje.trim().isNotEmpty)
              ? mensaje
              : _mensajePorCodigo(respuesta.statusCode),
          errors: validaciones,
        );
      }
    } on Exception {
      // El cuerpo no era json válido: se usa el mensaje de reserva.
    }
    return ApiException(_mensajePorCodigo(respuesta.statusCode));
  }

  /// Traduce una excepción que no viene de una respuesta http: fallos de red,
  /// tiempos agotados o validaciones hechas en el front antes de llamar a la api.
  static ApiException desdeExcepcion(Object error) {
    if (error is ApiException) return error;
    if (error is SocketException ||
        error is http.ClientException ||
        error is TimeoutException ||
        error is HandshakeException) {
      return const ApiException(mensajeSinConexion);
    }
    if (error is FormatException) {
      return const ApiException(mensajeGenerico);
    }
    if (error is Exception) {
      // Excepciones propias del front: se respeta su texto si lo tiene.
      final texto = error.toString().replaceFirst('Exception: ', '').trim();
      if (texto.isNotEmpty && texto != 'Exception') {
        return ApiException(texto);
      }
    }
    return const ApiException(mensajeGenerico);
  }

  /// Punto de entrada para la ui: cualquier `Error<T>.error` se normaliza aquí.
  static ApiException normalizar(Object error) => desdeExcepcion(error);

  static String _mensajePorCodigo(int codigo) => switch (codigo) {
    401 => 'Credenciales incorrectas',
    403 => mensajeSesionExpirada,
    404 => 'El recurso solicitado no existe',
    >= 500 => 'El servidor no pudo procesar la solicitud',
    _ => mensajeGenerico,
  };
}
