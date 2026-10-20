import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/env.dart';
import '../../../core/themes/dimens.dart';
import '../../../core/ui/widgets/barra_acento.dart';
import '../../domain/stores/salud_store.dart';

/// Pantalla que se ve cuando `/actuator/health` no responde `UP`. Explica qué
/// pasa, muestra los detalles técnicos y deja reintentar.
///
/// No tiene viewmodel: el estado lo lleva el [SaludStore], que es global
/// porque el `redirect` del router también lo lee.
class SinServidorScreen extends StatelessWidget {
  const SinServidorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dimens = Dimens.of(context);
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final salud = context.watch<SaludStore>();

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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: dimens.tamanoLogo,
                    color: esquema.error,
                  ),
                  const SizedBox(height: Dimens.espacioGrande),
                  Text(
                    'Servidor no disponible',
                    textAlign: TextAlign.center,
                    style: textos.headlineSmall?.copyWith(
                      color: esquema.onSurface,
                    ),
                  ),
                  const SizedBox(height: Dimens.espacioPequeno),
                  Text(
                    salud.mensaje,
                    textAlign: TextAlign.center,
                    style: textos.bodyMedium?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Dimens.espacioGrande),
                  if (salud.detalles.isNotEmpty)
                    _TarjetaDetalles(detalles: salud.detalles),
                  const SizedBox(height: Dimens.espacioGrande),
                  SizedBox(
                    height: Dimens.altoBoton,
                    child: FilledButton.icon(
                      onPressed: salud.verificando ? null : salud.verificar,
                      icon: salud.verificando
                          ? SizedBox(
                              width: Dimens.espacioMedio,
                              height: Dimens.espacioMedio,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: esquema.onPrimary,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        salud.verificando ? 'Comprobando…' : 'Reintentar',
                      ),
                    ),
                  ),
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

/// Detalles técnicos del fallo, en una tarjeta aparte para que no compitan con
/// el mensaje principal.
class _TarjetaDetalles extends StatelessWidget {
  const _TarjetaDetalles({required this.detalles});

  final List<String> detalles;

  @override
  Widget build(BuildContext context) {
    final dimens = Dimens.of(context);
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: dimens.edgeInsetsTarjeta,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarraAcento(),
            const SizedBox(height: Dimens.espacioPequeno),
            Text('Detalles', style: textos.titleSmall),
            const SizedBox(height: Dimens.espacioPequeno),
            for (final detalle in detalles)
              Padding(
                padding: const EdgeInsets.only(bottom: Dimens.espacioMinimo),
                child: Text(
                  detalle,
                  style: textos.bodySmall?.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
