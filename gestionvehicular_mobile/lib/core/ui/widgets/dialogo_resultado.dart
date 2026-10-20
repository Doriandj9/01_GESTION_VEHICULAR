import 'package:flutter/material.dart';

import '../../themes/dimens.dart';
import '../../utils/api_errors.dart';

/// Diálogo global con el que toda la app informa el resultado de una acción.
/// Ninguna pantalla define el suyo: el éxito y el error se muestran siempre
/// con este widget para que el aviso se vea igual en toda la app.
abstract final class DialogoResultado {
  /// Muestra un aviso de éxito con un solo mensaje.
  static Future<void> exito(
    BuildContext context, {
    required String mensaje,
    String titulo = 'Listo',
  }) {
    return _mostrar(
      context,
      titulo: titulo,
      mensaje: mensaje,
      validaciones: const {},
      esError: false,
    );
  }

  /// Muestra un aviso de error. Siempre pinta `message` y, si `errors` no está
  /// vacío, agrega sus pares campo -> mensaje en el mismo aviso.
  static Future<void> error(
    BuildContext context, {
    required Object error,
    String titulo = 'No se pudo continuar',
  }) {
    final apiError = ApiErrors.normalizar(error);
    return _mostrar(
      context,
      titulo: titulo,
      mensaje: apiError.message,
      validaciones: apiError.errors,
      esError: true,
    );
  }

  static Future<void> _mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required Map<String, String> validaciones,
    required bool esError,
  }) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final color = esError ? esquema.error : esquema.primary;

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          esError ? Icons.error_outline : Icons.check_circle_outline,
          color: color,
        ),
        title: Text(titulo, style: textos.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje, style: textos.bodyMedium),
            if (validaciones.isNotEmpty) ...[
              const SizedBox(height: Dimens.espacioMedio),
              ...validaciones.entries.map(
                (entrada) => Padding(
                  padding: const EdgeInsets.only(bottom: Dimens.espacioMinimo),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: textos.bodySmall),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${entrada.key}: ',
                                style: textos.labelMedium,
                              ),
                              TextSpan(
                                text: entrada.value,
                                style: textos.bodySmall?.copyWith(
                                  color: esquema.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
