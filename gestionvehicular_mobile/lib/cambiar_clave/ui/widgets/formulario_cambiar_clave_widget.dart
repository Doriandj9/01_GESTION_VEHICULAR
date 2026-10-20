import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/dimens.dart';
import '../../../core/ui/widgets/barra_acento.dart';
import '../../../core/ui/widgets/dialogo_resultado.dart';
import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../domain/models/sesion/usuario_model.dart';
import '../../../domain/stores/sesion_store.dart';
import '../viewmodels/cambiar_clave_viewmodel.dart';

/// Tarjeta con el formulario del cambio de clave. Es el widget que reacciona
/// al comando `cambiarClave`, por eso es `StatefulWidget`.
class FormularioCambiarClaveWidget extends StatefulWidget {
  const FormularioCambiarClaveWidget({super.key, required this.viewModel});

  final CambiarClaveViewmodel viewModel;

  @override
  State<FormularioCambiarClaveWidget> createState() =>
      _FormularioCambiarClaveWidgetState();
}

class _FormularioCambiarClaveWidgetState
    extends State<FormularioCambiarClaveWidget> {
  final Logger _log = Logger('FormularioCambiarClaveWidget');
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _repetidaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.cambiarClave.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant FormularioCambiarClaveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.cambiarClave.removeListener(_onResult);
    widget.viewModel.cambiarClave.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.cambiarClave.removeListener(_onResult);
    _actualController.dispose();
    _nuevaController.dispose();
    _repetidaController.dispose();
    super.dispose();
  }

  void _onResult() {
    final comando = widget.viewModel.cambiarClave;

    if (comando.completed) {
      comando.clearResult();
      _log.info('Clave cambiada; el router saca de /cambiar-clave');
      // Como en el login, el éxito no abre diálogo: el `redirect` lleva al
      // guardia a su pantalla y ese cambio ya es el aviso.
      return;
    }

    if (comando.error) {
      final resultado = comando.result;
      final error = resultado is Error<UsuarioModel>
          ? resultado.error
          : const ApiException(ApiErrors.mensajeGenerico);
      comando.clearResult();
      // Igual que la web: tras un error se vacían los tres campos.
      widget.viewModel.limpiarCampos();
      _actualController.clear();
      _nuevaController.clear();
      _repetidaController.clear();
      _log.info('Error al cambiar la clave');
      if (!mounted) return;
      DialogoResultado.error(
        context,
        error: error,
        titulo: 'No se pudo cambiar la clave',
      );
    }
  }

  void _enviar() {
    if (!widget.viewModel.puedeEnviar) return;
    FocusScope.of(context).unfocus();
    widget.viewModel.cambiarClave.execute((
      widget.viewModel.claveActual,
      widget.viewModel.claveNueva,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final dimens = Dimens.of(context);

    return Card(
      child: Padding(
        padding: dimens.edgeInsetsTarjeta,
        child: ListenableBuilder(
          // Un solo listenable para los dos: el viewmodel notifica en cada
          // tecla y el comando al correr o terminar.
          listenable: Listenable.merge([
            widget.viewModel,
            widget.viewModel.cambiarClave,
          ]),
          builder: (context, _) {
            final vm = widget.viewModel;
            final cargando = vm.cambiarClave.running;
            final visibles = vm.clavesVisibles;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BarraAcento(),
                const SizedBox(height: Dimens.espacioPequeno),
                Text('Clave nueva', style: textos.titleSmall),
                const SizedBox(height: Dimens.espacioGrande),

                TextField(
                  controller: _actualController,
                  enabled: !cargando,
                  obscureText: !visibles,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  onChanged: vm.actualizarClaveActual,
                  decoration: InputDecoration(
                    labelText: 'Clave actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: visibles ? 'Ocultar claves' : 'Mostrar claves',
                      icon: Icon(
                        visibles
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: vm.alternarVisibilidadClaves,
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.espacioMedio),

                TextField(
                  controller: _nuevaController,
                  enabled: !cargando,
                  obscureText: !visibles,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: vm.actualizarClaveNueva,
                  decoration: const InputDecoration(
                    labelText: 'Clave nueva',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                ),

                if (vm.claveNueva.isNotEmpty) ...[
                  const SizedBox(height: Dimens.espacioPequeno),
                  _IndicadorFortaleza(nivel: vm.fortaleza),
                ],

                const SizedBox(height: Dimens.espacioPequeno),
                // Métricas que debe cumplir la clave, en vivo.
                ...vm.reglas.map(
                  (regla) => _Regla(texto: regla.texto, cumple: regla.cumple),
                ),
                _Regla(
                  texto: 'Distinta de la clave actual',
                  cumple: vm.claveEsDistinta,
                ),

                const SizedBox(height: Dimens.espacioMedio),
                TextField(
                  controller: _repetidaController,
                  enabled: !cargando,
                  obscureText: !visibles,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: vm.actualizarClaveRepetida,
                  onSubmitted: (_) => _enviar(),
                  decoration: InputDecoration(
                    labelText: 'Repita la clave nueva',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText:
                        vm.claveRepetida.isNotEmpty && !vm.clavesCoinciden
                        ? 'Las claves no coinciden.'
                        : null,
                  ),
                ),

                const SizedBox(height: Dimens.espacioGrande),
                SizedBox(
                  height: Dimens.altoBoton,
                  child: FilledButton(
                    onPressed: vm.puedeEnviar ? _enviar : null,
                    child: cargando
                        ? SizedBox(
                            width: Dimens.espacioGrande,
                            height: Dimens.espacioGrande,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: esquema.onPrimary,
                            ),
                          )
                        : const Text('Cambiar clave'),
                  ),
                ),
                const SizedBox(height: Dimens.espacioPequeno),
                // Única salida además de cambiar la clave.
                TextButton(
                  onPressed: cargando
                      ? null
                      : () => context.read<SesionStore>().cerrarSesion(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Barra de tres segmentos con la fortaleza de la clave nueva (0 a 3).
class _IndicadorFortaleza extends StatelessWidget {
  const _IndicadorFortaleza({required this.nivel});

  final int nivel;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (final segmento in const [1, 2, 3])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: Dimens.espacioMinimo),
              child: Container(
                height: Dimens.altoAcento,
                decoration: BoxDecoration(
                  color: nivel >= segmento
                      ? esquema.primary
                      : esquema.outlineVariant,
                  borderRadius: BorderRadius.circular(Dimens.altoAcento),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Una métrica de la clave con su marca de cumplida.
class _Regla extends StatelessWidget {
  const _Regla({required this.texto, required this.cumple});

  final String texto;
  final bool cumple;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final color = cumple ? esquema.primary : esquema.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: Dimens.espacioMinimo),
      child: Row(
        children: [
          Icon(
            cumple ? Icons.check_circle : Icons.circle_outlined,
            size: Dimens.espacioMedio,
            color: color,
          ),
          const SizedBox(width: Dimens.espacioPequeno),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
