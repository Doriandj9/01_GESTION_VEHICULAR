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
import '../../domain/validaciones_inicio_sesion.dart';
import '../viewmodels/inicio_sesion_viewmodel.dart';

/// Tarjeta con el formulario de credenciales. Es el widget que reacciona al
/// comando `iniciarSesion`, por eso es `StatefulWidget`.
class FormularioInicioSesionWidget extends StatefulWidget {
  const FormularioInicioSesionWidget({super.key, required this.viewModel});

  final InicioSesionViewmodel viewModel;

  @override
  State<FormularioInicioSesionWidget> createState() =>
      _FormularioInicioSesionWidgetState();
}

class _FormularioInicioSesionWidgetState
    extends State<FormularioInicioSesionWidget> {
  final Logger _log = Logger('FormularioInicioSesionWidget');
  final _formulario = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.iniciarSesion.addListener(_onResult);
    // Si se llegó aquí porque el jwt dejó de servir, se avisa una sola vez.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _avisarSesionExpirada(),
    );
  }

  @override
  void didUpdateWidget(covariant FormularioInicioSesionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.iniciarSesion.removeListener(_onResult);
    widget.viewModel.iniciarSesion.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.iniciarSesion.removeListener(_onResult);
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onResult() {
    final comando = widget.viewModel.iniciarSesion;

    if (comando.completed) {
      comando.clearResult();
      _log.info('Sesión iniciada; el router redirige según el rol y el estado');
      // En el éxito no se abre diálogo: el `redirect` del router lleva al
      // guardia a su pantalla y ese cambio ya es el aviso visible.
      return;
    }

    if (comando.error) {
      final resultado = comando.result;
      final error = resultado is Error<UsuarioModel>
          ? resultado.error
          : const ApiException(ApiErrors.mensajeGenerico);
      comando.clearResult();
      _log.info('Error al iniciar sesión');
      if (!mounted) return;
      DialogoResultado.error(
        context,
        error: error,
        titulo: 'No se pudo iniciar sesión',
      );
    }
  }

  void _avisarSesionExpirada() {
    if (!mounted) return;
    final sesion = context.read<SesionStore>();
    if (!sesion.sesionExpirada) return;
    sesion.consumirSesionExpirada();
    DialogoResultado.error(
      context,
      error: const ApiException(ApiErrors.mensajeSesionExpirada),
      titulo: 'Sesión finalizada',
    );
  }

  void _enviar() {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    widget.viewModel.iniciarSesion.execute((
      _correoController.text,
      _passwordController.text,
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
          listenable: widget.viewModel.iniciarSesion,
          builder: (context, _) {
            final cargando = widget.viewModel.iniciarSesion.running;

            return Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BarraAcento(),
                  const SizedBox(height: Dimens.espacioPequeno),
                  Text('Iniciar sesión', style: textos.titleSmall),
                  const SizedBox(height: Dimens.espacioMinimo),
                  Text(
                    'Use las credenciales entregadas por la entidad.',
                    style: textos.bodySmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Dimens.espacioGrande),
                  TextFormField(
                    controller: _correoController,
                    enabled: !cargando,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      hintText: 'nombre@dominio.gob.ec',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: ValidacionesInicioSesion.correo,
                  ),
                  const SizedBox(height: Dimens.espacioMedio),
                  ListenableBuilder(
                    listenable: widget.viewModel,
                    builder: (context, _) {
                      final visible = widget.viewModel.claveVisible;

                      return TextFormField(
                        controller: _passwordController,
                        enabled: !cargando,
                        obscureText: !visible,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => cargando ? null : _enviar(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: visible
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                            icon: Icon(
                              visible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed:
                                widget.viewModel.alternarVisibilidadClave,
                          ),
                        ),
                        validator: ValidacionesInicioSesion.password,
                      );
                    },
                  ),
                  const SizedBox(height: Dimens.espacioGrande),
                  SizedBox(
                    height: Dimens.altoBoton,
                    child: FilledButton(
                      onPressed: cargando ? null : _enviar,
                      child: cargando
                          ? SizedBox(
                              width: Dimens.espacioGrande,
                              height: Dimens.espacioGrande,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: esquema.onPrimary,
                              ),
                            )
                          : const Text('Ingresar'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
