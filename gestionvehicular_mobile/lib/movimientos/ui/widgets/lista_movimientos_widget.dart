import 'package:flutter/material.dart';

import '../../../core/themes/dimens.dart';
import '../../../core/ui/widgets/barra_acento.dart';
import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../domain/models/movimiento_registrado_model.dart';
import '../../domain/models/tipo_movimiento.dart';
import '../viewmodels/movimientos_viewmodel.dart';

/// Listado de los movimientos que registró el guardia, con filtro por fecha
/// (por defecto hoy). Va debajo de las acciones y sirve de confirmación: si el
/// registro quedó guardado, aparece aquí arriba.
class ListaMovimientosWidget extends StatelessWidget {
  const ListaMovimientosWidget({super.key, required this.viewModel});

  /// Cuántos movimientos se muestran como máximo. Es un listado de apoyo, no
  /// un reporte: eso es de la web de administración.
  static const maximoVisible = 10;

  final MovimientosViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.espacioMedio),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            viewModel,
            viewModel.cargarMovimientos,
          ]),
          builder: (context, _) {
            final comando = viewModel.cargarMovimientos;
            final movimientos = viewModel.movimientos;
            final resultado = comando.result;
            final mensajeError =
                resultado is Error<List<MovimientoRegistradoModel>>
                ? ApiErrors.normalizar(resultado.error).message
                : ApiErrors.mensajeGenerico;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BarraAcento(),
                const SizedBox(height: Dimens.espacioPequeno),
                Row(
                  children: [
                    Expanded(
                      child: Text('Mis registros', style: textos.titleSmall),
                    ),
                    IconButton(
                      tooltip: 'Actualizar',
                      icon: const Icon(Icons.refresh),
                      onPressed: comando.running ? null : comando.execute,
                    ),
                  ],
                ),
                _FiltroFecha(viewModel: viewModel),
                const SizedBox(height: Dimens.espacioPequeno),

                if (comando.running)
                  const Padding(
                    padding: EdgeInsets.all(Dimens.espacioGrande),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (comando.error)
                  _Aviso(
                    icono: Icons.error_outline,
                    color: esquema.error,
                    texto: mensajeError,
                    textos: textos,
                    accion: TextButton(
                      onPressed: comando.execute,
                      child: const Text('Reintentar'),
                    ),
                  )
                else if (movimientos.isEmpty)
                  _Aviso(
                    icono: Icons.inbox_outlined,
                    color: esquema.onSurfaceVariant,
                    texto: viewModel.filtraHoy
                        ? 'Todavía no ha registrado movimientos hoy.'
                        : 'No hay movimientos registrados desde esa fecha.',
                    textos: textos,
                  )
                else ...[
                  for (final movimiento in movimientos.take(maximoVisible))
                    _FilaMovimiento(movimiento: movimiento),
                  if (movimientos.length > maximoVisible)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: Dimens.espacioPequeno,
                      ),
                      child: Text(
                        'Mostrando los $maximoVisible más recientes '
                        'de ${movimientos.length}.',
                        style: textos.labelSmall?.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Fila del filtro: la fecha desde la que se listan los movimientos.
///
/// Se rotula "Desde" y no "Fecha" porque la api interpreta el parámetro como
/// un desde inclusive: al elegir un día anterior se ven también los posteriores.
class _FiltroFecha extends StatelessWidget {
  const _FiltroFecha({required this.viewModel});

  final MovimientosViewmodel viewModel;

  Future<void> _elegirFecha(BuildContext context) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: viewModel.fechaFiltro,
      // No tiene sentido listar movimientos de un futuro que no existe.
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
      helpText: 'Movimientos desde',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );
    if (elegida == null) return;
    await viewModel.cambiarFecha(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final fecha = viewModel.fechaFiltro;
    final etiqueta = viewModel.filtraHoy
        ? 'Hoy'
        : '${fecha.day.toString().padLeft(2, '0')}/'
              '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    return Row(
      children: [
        Text(
          'Desde',
          style: textos.labelMedium?.copyWith(color: esquema.onSurfaceVariant),
        ),
        const SizedBox(width: Dimens.espacioPequeno),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _elegirFecha(context),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(etiqueta),
            ),
          ),
        ),
        if (!viewModel.filtraHoy)
          TextButton(onPressed: viewModel.volverAHoy, child: const Text('Hoy')),
      ],
    );
  }
}

/// Una fila del listado: tipo, hora, placa y conductor.
class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento({required this.movimiento});

  final MovimientoRegistradoModel movimiento;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final fecha = movimiento.fecha.toLocal();
    final hora =
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
    final dia =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}';
    final esEntrada = movimiento.tipo == TipoMovimiento.entrada;

    return Padding(
      padding: const EdgeInsets.only(top: Dimens.espacioPequeno),
      child: Row(
        children: [
          // El tipo se distingue por icono y no solo por color, para que se
          // lea también a plena luz del sol.
          Container(
            width: Dimens.espacioExtra,
            height: Dimens.espacioExtra,
            decoration: BoxDecoration(
              color: esEntrada
                  ? esquema.primaryContainer
                  : esquema.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Dimens.radioBoton),
            ),
            child: Icon(
              esEntrada ? Icons.login : Icons.logout,
              size: Dimens.espacioMedio,
              color: esEntrada ? esquema.primary : esquema.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Dimens.espacioPequeno),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.placa ?? 'Vehículo sin placa',
                  style: textos.labelLarge,
                ),
                Text(
                  [
                    movimiento.tipo.etiqueta,
                    if (movimiento.conductor != null &&
                        movimiento.conductor!.isNotEmpty)
                      movimiento.conductor!,
                    if (movimiento.ubicacion == null) 'sin ubicación',
                  ].join(' · '),
                  style: textos.bodySmall?.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(hora, style: textos.labelMedium),
              Text(
                dia,
                style: textos.labelSmall?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Aviso de lista vacía o de error.
class _Aviso extends StatelessWidget {
  const _Aviso({
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.espacioMedio),
      child: Column(
        children: [
          Icon(icono, color: color, size: Dimens.espacioGrande),
          const SizedBox(height: Dimens.espacioPequeno),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: textos.bodySmall?.copyWith(color: color),
          ),
          ?accion,
        ],
      ),
    );
  }
}
