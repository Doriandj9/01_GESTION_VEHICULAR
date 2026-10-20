import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../core/themes/dimens.dart';
import '../../../core/ui/widgets/dialogo_resultado.dart';
import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../domain/models/sesion/usuario_model.dart';
import '../../../inicio_sesion/ui/viewmodels/inicio_sesion_viewmodel.dart';

/// Icono de biometría en la parte inferior del login. Solo aparece cuando el
/// dispositivo tiene huella o rostro registrados **y** hay una credencial
/// vigente guardada; en cualquier otro caso no ocupa espacio.
///
/// Reacciona al comando `iniciarSesionBiometrica`, por eso es `StatefulWidget`.
class AccesoBiometricoWidget extends StatefulWidget {
  const AccesoBiometricoWidget({super.key, required this.viewModel});

  final InicioSesionViewmodel viewModel;

  @override
  State<AccesoBiometricoWidget> createState() => _AccesoBiometricoWidgetState();
}

class _AccesoBiometricoWidgetState extends State<AccesoBiometricoWidget> {
  final Logger _log = Logger('AccesoBiometricoWidget');

  @override
  void initState() {
    super.initState();
    widget.viewModel.iniciarSesionBiometrica.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant AccesoBiometricoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.iniciarSesionBiometrica.removeListener(_onResult);
    widget.viewModel.iniciarSesionBiometrica.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.iniciarSesionBiometrica.removeListener(_onResult);
    super.dispose();
  }

  void _onResult() {
    final comando = widget.viewModel.iniciarSesionBiometrica;

    if (comando.completed) {
      comando.clearResult();
      _log.info('Sesión iniciada con biometría; el router redirige');
      // Igual que en el login con clave: el éxito no abre diálogo, la
      // redirección del router ya es el aviso.
      return;
    }

    if (comando.error) {
      final resultado = comando.result;
      final error = resultado is Error<UsuarioModel>
          ? resultado.error
          : const ApiException(ApiErrors.mensajeGenerico);
      comando.clearResult();
      if (!mounted) return;
      DialogoResultado.error(
        context,
        error: error,
        titulo: 'No se pudo ingresar',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.viewModel,
        widget.viewModel.iniciarSesionBiometrica,
        widget.viewModel.iniciarSesion,
      ]),
      builder: (context, _) {
        if (!widget.viewModel.puedeUsarBiometria) {
          return const SizedBox.shrink();
        }

        final comando = widget.viewModel.iniciarSesionBiometrica;
        // Mientras corre el login con clave tampoco se deja pulsar la huella.
        final ocupado =
            comando.running || widget.viewModel.iniciarSesion.running;
        final correo = widget.viewModel.credencial!.correo;

        return Column(
          children: [
            const SizedBox(height: Dimens.espacioGrande),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.espacioPequeno,
                  ),
                  child: Text(
                    'o ingrese con su huella',
                    style: textos.labelSmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: Dimens.espacioMedio),
            _BotonHuella(
              ocupado: ocupado,
              cargando: comando.running,
              onPressed: comando.execute,
            ),
            const SizedBox(height: Dimens.espacioPequeno),
            // Se muestra a quién se va a entrar: en un teléfono de garita con
            // varias huellas registradas, esto evita sorpresas.
            Text(
              correo,
              textAlign: TextAlign.center,
              style: textos.labelMedium?.copyWith(color: esquema.onSurface),
            ),
          ],
        );
      },
    );
  }
}

/// Círculo pulsable con el icono de la huella.
class _BotonHuella extends StatelessWidget {
  const _BotonHuella({
    required this.ocupado,
    required this.cargando,
    required this.onPressed,
  });

  final bool ocupado;
  final bool cargando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Center(
      child: Tooltip(
        message: 'Ingresar con la biometría del dispositivo',
        child: InkWell(
          onTap: ocupado ? null : onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: Dimens.tamanoBotonHuella,
            height: Dimens.tamanoBotonHuella,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: esquema.primaryContainer,
              border: Border.all(
                color: esquema.primary,
                width: Dimens.grosorBorde,
              ),
            ),
            child: cargando
                ? Padding(
                    padding: const EdgeInsets.all(Dimens.espacioMedio),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: esquema.primary,
                    ),
                  )
                : Icon(
                    Icons.fingerprint,
                    size: Dimens.espacioExtra,
                    color: ocupado ? esquema.onSurfaceVariant : esquema.primary,
                  ),
          ),
        ),
      ),
    );
  }
}
