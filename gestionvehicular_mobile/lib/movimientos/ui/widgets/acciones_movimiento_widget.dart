import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../core/themes/dimens.dart';
import '../../../core/ui/widgets/dialogo_resultado.dart';
import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../domain/models/movimiento_model.dart';
import '../../domain/models/tipo_movimiento.dart';
import '../viewmodels/movimientos_viewmodel.dart';
import 'escaner_qr_screen.dart';

/// Las dos acciones del guardia: primero **Salida** y luego **Entrada**. Cada
/// una abre el escáner y, con el texto del QR, registra el movimiento.
///
/// Es el widget que reacciona al comando `registrar`, por eso es
/// `StatefulWidget`.
class AccionesMovimientoWidget extends StatefulWidget {
  const AccionesMovimientoWidget({super.key, required this.viewModel});

  final MovimientosViewmodel viewModel;

  @override
  State<AccionesMovimientoWidget> createState() =>
      _AccionesMovimientoWidgetState();
}

class _AccionesMovimientoWidgetState extends State<AccionesMovimientoWidget> {
  final Logger _log = Logger('AccionesMovimientoWidget');

  @override
  void initState() {
    super.initState();
    widget.viewModel.registrar.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant AccionesMovimientoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.registrar.removeListener(_onResult);
    widget.viewModel.registrar.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.registrar.removeListener(_onResult);
    super.dispose();
  }

  void _onResult() {
    final comando = widget.viewModel.registrar;

    if (comando.completed) {
      final resultado = comando.result;
      final movimiento = resultado is Ok<MovimientoModel>
          ? resultado.value
          : null;
      comando.clearResult();
      _log.info('Movimiento registrado');
      if (!mounted || movimiento == null) return;
      DialogoResultado.exito(
        context,
        titulo: '${movimiento.tipo.etiqueta} registrada',
        mensaje: movimiento.ubicacion == null
            ? 'Se registró a las ${_hora(movimiento.registro)}, sin ubicación.'
            : 'Se registró a las ${_hora(movimiento.registro)}.',
      );
      return;
    }

    if (comando.error) {
      final resultado = comando.result;
      final error = resultado is Error<MovimientoModel>
          ? resultado.error
          : const ApiException(ApiErrors.mensajeGenerico);
      comando.clearResult();
      _log.info('Error al registrar el movimiento');
      if (!mounted) return;
      DialogoResultado.error(
        context,
        error: error,
        titulo: 'No se pudo registrar',
      );
    }
  }

  /// Hora del registro en formato de 24 h.
  String _hora(DateTime fecha) {
    final hh = fecha.hour.toString().padLeft(2, '0');
    final mm = fecha.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Abre el escáner y, si se leyó un código, registra el movimiento.
  Future<void> _escanearYRegistrar(TipoMovimiento tipo) async {
    final data = await EscanerQrScreen.abrir(context, tipo);
    if (data == null) {
      _log.info('Escaneo cancelado para ${tipo.valor}');
      return;
    }
    await widget.viewModel.registrar.execute((data, tipo));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel.registrar,
      builder: (context, _) {
        final registrando = widget.viewModel.registrar.running;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // El orden lo fija el uso: primero la salida, luego la entrada.
            _TarjetaAccion(
              tipo: TipoMovimiento.salida,
              icono: Icons.logout,
              descripcion: 'El vehículo sale del parqueadero',
              enCurso:
                  registrando &&
                  widget.viewModel.tipoEnCurso == TipoMovimiento.salida,
              habilitada: !registrando,
              onPulsar: () => _escanearYRegistrar(TipoMovimiento.salida),
            ),
            const SizedBox(height: Dimens.espacioMedio),
            _TarjetaAccion(
              tipo: TipoMovimiento.entrada,
              icono: Icons.login,
              descripcion: 'El vehículo ingresa al parqueadero',
              enCurso:
                  registrando &&
                  widget.viewModel.tipoEnCurso == TipoMovimiento.entrada,
              habilitada: !registrando,
              onPulsar: () => _escanearYRegistrar(TipoMovimiento.entrada),
            ),
          ],
        );
      },
    );
  }
}

/// Tarjeta pulsable de un tipo de movimiento. Es una tarjeta y no un botón de
/// color porque las dos acciones tienen el mismo peso y el lenguaje visual solo
/// admite un botón verde por pantalla.
class _TarjetaAccion extends StatelessWidget {
  const _TarjetaAccion({
    required this.tipo,
    required this.icono,
    required this.descripcion,
    required this.enCurso,
    required this.habilitada,
    required this.onPulsar,
  });

  final TipoMovimiento tipo;
  final IconData icono;
  final String descripcion;
  final bool enCurso;
  final bool habilitada;
  final VoidCallback onPulsar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Opacity(
      opacity: habilitada || enCurso ? 1 : 0.5,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: habilitada ? onPulsar : null,
          child: Padding(
            padding: const EdgeInsets.all(Dimens.espacioMedio),
            child: Row(
              children: [
                Container(
                  width: Dimens.altoBoton,
                  height: Dimens.altoBoton,
                  decoration: BoxDecoration(
                    color: esquema.primaryContainer,
                    borderRadius: BorderRadius.circular(Dimens.radioBoton),
                  ),
                  child: enCurso
                      ? Padding(
                          padding: const EdgeInsets.all(Dimens.espacioPequeno),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: esquema.primary,
                          ),
                        )
                      : Icon(icono, color: esquema.primary),
                ),
                const SizedBox(width: Dimens.espacioMedio),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo.etiqueta.toUpperCase(),
                        style: textos.titleSmall,
                      ),
                      const SizedBox(height: Dimens.espacioMinimo),
                      Text(
                        enCurso ? 'Registrando…' : descripcion,
                        style: textos.bodySmall?.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.qr_code_scanner, color: esquema.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
