import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/env.dart';
import '../../../core/themes/dimens.dart';
import '../../../domain/stores/sesion_store.dart';
import '../viewmodels/cambiar_clave_viewmodel.dart';
import 'formulario_cambiar_clave_widget.dart';

/// Pantalla del cambio obligatorio de clave (usuario en estado `INICIAL`).
///
/// No tiene vuelta atrás: el `redirect` del router no deja salir de aquí
/// mientras el estado siga siendo `INICIAL`. La única salida es cambiar la
/// clave o cerrar la sesión.
class CambiarClaveScreen extends StatelessWidget {
  const CambiarClaveScreen({super.key, required this.viewModel});

  final CambiarClaveViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final dimens = Dimens.of(context);
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final usuario = context.watch<SesionStore>().usuario;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: dimens.edgeInsetsScreenSymmetric,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dimens.anchoMaximoContenido,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_reset_outlined,
                    size: dimens.tamanoLogo / 2,
                    color: esquema.primary,
                  ),
                  const SizedBox(height: Dimens.espacioMedio),
                  Text(
                    'Cambie su clave',
                    textAlign: TextAlign.center,
                    style: textos.headlineSmall?.copyWith(
                      color: esquema.onSurface,
                    ),
                  ),
                  const SizedBox(height: Dimens.espacioMinimo),
                  Text(
                    'Su cuenta usa una clave inicial. Debe cambiarla para continuar.',
                    textAlign: TextAlign.center,
                    style: textos.bodyMedium?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  if (usuario != null) ...[
                    const SizedBox(height: Dimens.espacioMinimo),
                    Text(
                      usuario.correo,
                      textAlign: TextAlign.center,
                      style: textos.labelMedium?.copyWith(
                        color: esquema.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: Dimens.espacioGrande),
                  FormularioCambiarClaveWidget(viewModel: viewModel),
                  const SizedBox(height: Dimens.espacioGrande),
                  Text(
                    Env.entidadNombre,
                    textAlign: TextAlign.center,
                    style: textos.labelSmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
