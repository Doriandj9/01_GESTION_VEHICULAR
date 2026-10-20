import 'package:flutter/material.dart';

import '../../../acceso_biometrico/ui/widgets/acceso_biometrico_widget.dart';
import '../../../config/env.dart';
import '../../../core/themes/dimens.dart';
import '../viewmodels/inicio_sesion_viewmodel.dart';
import 'formulario_inicio_sesion_widget.dart';

/// Pantalla inicial de la app: inicio de sesión del guardia.
///
/// Interfaz minimalista y sin `AppBar`: un sello de marca, el título, y una
/// sola tarjeta con el formulario. Todo el color sale del `colorScheme` y
/// todas las medidas de `Dimens`.
class InicioSesionScreen extends StatelessWidget {
  const InicioSesionScreen({super.key, required this.viewModel});

  final InicioSesionViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final dimens = Dimens.of(context);
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

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
                  _SelloMarca(tamano: dimens.tamanoLogo),
                  const SizedBox(height: Dimens.espacioGrande),
                  Text(
                    'Gestión Vehicular',
                    textAlign: TextAlign.center,
                    style: textos.headlineMedium?.copyWith(
                      color: esquema.onSurface,
                    ),
                  ),
                  const SizedBox(height: Dimens.espacioMinimo),
                  Text(
                    Env.entidadAlias,
                    textAlign: TextAlign.center,
                    style: textos.bodyMedium?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Dimens.espacioExtra),
                  FormularioInicioSesionWidget(viewModel: viewModel),
                  // Debajo del formulario: el acceso con huella. Se pinta solo
                  // si el dispositivo recuerda a un guardia.
                  AccesoBiometricoWidget(viewModel: viewModel),
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

/// Sello de marca: cuadrado verde suave con el icono de la app. Sustituye al
/// logotipo mientras no exista el archivo en `assets/img/`.
class _SelloMarca extends StatelessWidget {
  const _SelloMarca({required this.tamano});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          color: esquema.primaryContainer,
          borderRadius: BorderRadius.circular(Dimens.radioTarjeta),
        ),
        child: Icon(
          Icons.directions_car_filled_outlined,
          size: tamano / 2,
          color: esquema.primary,
        ),
      ),
    );
  }
}
