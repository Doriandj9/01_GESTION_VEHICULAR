import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/env.dart';
import '../../../core/themes/dimens.dart';
import '../../../core/ui/widgets/barra_acento.dart';
import '../../../domain/stores/sesion_store.dart';
import '../../../inicio_sesion/domain/use_cases/cerrar_sesion_use_case.dart';
import '../viewmodels/movimientos_viewmodel.dart';
import 'acciones_movimiento_widget.dart';
import 'aviso_ubicacion_widget.dart';
import 'lista_movimientos_widget.dart';

/// Pantalla principal del guardia: registrar la salida o la entrada de un
/// vehículo escaneando su código QR.
class MovimientosScreen extends StatelessWidget {
  const MovimientosScreen({super.key, required this.viewModel});

  final MovimientosViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final dimens = Dimens.of(context);
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final usuario = context.watch<SesionStore>().usuario;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gestión Vehicular'),
            Text(Env.entidadAlias, style: textos.labelSmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(Icons.logout),
            // Cerrar sesión también borra el acceso biométrico: lo hace el
            // caso de uso, no el store.
            onPressed: () => context.read<CerrarSesionUseCase>().ejecutar(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: dimens.edgeInsetsScreenSymmetric,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dimens.anchoMaximoContenido,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BarraAcento(),
                  const SizedBox(height: Dimens.espacioPequeno),
                  Text('Registrar movimiento', style: textos.headlineSmall),
                  const SizedBox(height: Dimens.espacioMinimo),
                  Text(
                    usuario == null
                        ? 'Escanee el código QR del vehículo.'
                        : '${usuario.nombres} · ${usuario.rol.etiqueta}',
                    style: textos.bodyMedium?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Dimens.espacioMedio),
                  AvisoUbicacionWidget(viewModel: viewModel),
                  const SizedBox(height: Dimens.espacioMedio),
                  AccionesMovimientoWidget(viewModel: viewModel),
                  const SizedBox(height: Dimens.espacioMedio),
                  ListaMovimientosWidget(viewModel: viewModel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
