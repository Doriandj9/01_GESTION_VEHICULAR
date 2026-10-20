import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';

/// Pantalla que se ve mientras se restaura la sesión guardada al abrir la app.
/// Es la ruta inicial: el `redirect` sale de aquí en cuanto la sesión se
/// resuelve (al login o a la pantalla del guardia).
class PantallaCargando extends StatelessWidget {
  const PantallaCargando({super.key});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: esquema.primary),
            const SizedBox(height: Dimens.espacioMedio),
            Text(
              'Cargando…',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
