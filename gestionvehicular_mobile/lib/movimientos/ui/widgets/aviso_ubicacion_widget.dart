import 'package:flutter/material.dart';

import '../../../core/themes/dimens.dart';
import '../../data/services/ubicacion_service.dart';
import '../viewmodels/movimientos_viewmodel.dart';

/// Estado del permiso de ubicación. Se muestra antes de las acciones para que
/// el guardia sepa si el movimiento quedará con coordenadas o sin ellas.
///
/// Nunca bloquea el registro: la api acepta `latitud` y `longitud` vacías.
class AvisoUbicacionWidget extends StatelessWidget {
  const AvisoUbicacionWidget({super.key, required this.viewModel});

  final MovimientosViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.pedirUbicacion]),
      builder: (context, _) {
        if (viewModel.pedirUbicacion.running) {
          return _Franja(
            icono: Icons.my_location,
            color: esquema.onSurfaceVariant,
            texto: 'Comprobando el permiso de ubicación…',
            textos: textos,
          );
        }

        final estado = viewModel.estadoUbicacion;
        if (estado == null) return const SizedBox.shrink();

        if (estado.permiteUbicar) {
          return _Franja(
            icono: Icons.location_on,
            color: esquema.primary,
            texto: 'El movimiento se registrará con su ubicación.',
            textos: textos,
          );
        }

        // Permiso negado, negado para siempre o gps apagado: se avisa y se
        // ofrece la acción que corresponda, pero se puede registrar igual.
        return _Franja(
          icono: Icons.location_off,
          color: esquema.error,
          texto: switch (estado) {
            EstadoPermisoUbicacion.servicioApagado =>
              'La ubicación del teléfono está apagada. El movimiento se '
                  'registrará sin coordenadas.',
            EstadoPermisoUbicacion.negadoParaSiempre =>
              'El permiso de ubicación está negado en los ajustes. El '
                  'movimiento se registrará sin coordenadas.',
            _ =>
              'Sin permiso de ubicación. El movimiento se registrará sin '
                  'coordenadas.',
          },
          textos: textos,
          accion: estado == EstadoPermisoUbicacion.negadoParaSiempre
              ? TextButton(
                  onPressed: viewModel.abrirAjustes,
                  child: const Text('Abrir ajustes'),
                )
              : TextButton(
                  onPressed: viewModel.pedirUbicacion.execute,
                  child: const Text('Permitir ubicación'),
                ),
        );
      },
    );
  }
}

/// Franja de aviso con icono, texto y una acción opcional.
class _Franja extends StatelessWidget {
  const _Franja({
    required this.icono,
    required this.color,
    required this.texto,
    required this.textos,
    this.accion,
  });

  final IconData icono;
  final Color color;
  final String texto;
  final TextTheme textos;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.espacioMedio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: color, size: Dimens.espacioGrande),
                const SizedBox(width: Dimens.espacioPequeno),
                Expanded(
                  child: Text(
                    texto,
                    style: textos.bodySmall?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            if (accion != null)
              Align(alignment: Alignment.centerRight, child: accion),
          ],
        ),
      ),
    );
  }
}
