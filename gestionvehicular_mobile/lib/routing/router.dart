import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../cambiar_clave/ui/viewmodels/cambiar_clave_viewmodel.dart';
import '../cambiar_clave/ui/widgets/cambiar_clave_screen.dart';
import '../domain/models/sesion/rol_usuario.dart';
import '../domain/stores/sesion_store.dart';
import '../inicio_sesion/ui/viewmodels/inicio_sesion_viewmodel.dart';
import '../inicio_sesion/ui/widgets/inicio_sesion_screen.dart';
import '../movimientos/ui/viewmodels/movimientos_viewmodel.dart';
import '../movimientos/ui/widgets/movimientos_screen.dart';
import '../salud_servidor/domain/stores/salud_store.dart';
import '../salud_servidor/ui/widgets/sin_servidor_screen.dart';
import 'routes.dart';
import 'widgets/pantalla_cargando.dart';

/// `GoRouter` único de la app. Escucha el [SaludStore] y el [SesionStore] para
/// redirigir cuando el servidor o la sesión cambian (login, logout, jwt
/// expirado o backend caído).
///
/// Los viewmodels se construyen aquí, en el `builder` de cada ruta, con
/// `context.read()`: nunca se registran en `provider`.
GoRouter crearRouter(SesionStore sesionStore, SaludStore saludStore) =>
    GoRouter(
      initialLocation: AppRoutes.cargando,
      debugLogDiagnostics: true,
      refreshListenable: Listenable.merge([saludStore, sesionStore]),
      redirect: _redirigir,
      routes: [
        GoRoute(
          path: AppRoutes.cargando,
          builder: (context, state) => const PantallaCargando(),
        ),
        GoRoute(
          path: AppRoutes.sinServidor,
          builder: (context, state) => const SinServidorScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => InicioSesionScreen(
            viewModel: InicioSesionViewmodel(
              iniciarSesionUseCase: context.read(),
              iniciarSesionBiometricaUseCase: context.read(),
              accesoBiometricoRepository: context.read(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.cambiarClave,
          builder: (context, state) => CambiarClaveScreen(
            viewModel: CambiarClaveViewmodel(
              cambiarClaveUseCase: context.read(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.movimientos,
          builder: (context, state) => MovimientosScreen(
            viewModel: MovimientosViewmodel(
              registrarMovimientoUseCase: context.read(),
              listarMisMovimientosUseCase: context.read(),
              ubicacionService: context.read(),
            ),
          ),
        ),
      ],
    );

/// Reglas de navegación según el servidor y el estado de la sesión:
/// - sondeando `/actuator/health` -> pantalla de carga;
/// - servidor caído -> `/sin-servidor`;
/// - restaurando la sesión -> pantalla de carga;
/// - sin sesión -> `/login`;
/// - usuario en estado `INICIAL` -> `/cambiar-clave` (y no puede salir de ahí);
/// - rol `GUARDIA` -> `/movimientos`.
String? _redirigir(BuildContext context, GoRouterState state) {
  final salud = context.read<SaludStore>();
  final sesion = context.read<SesionStore>();
  final destino = state.matchedLocation;

  // Lo primero es el servidor: sin él no hay login ni sesión que restaurar.
  if (salud.verificando) {
    return destino == AppRoutes.cargando ? null : AppRoutes.cargando;
  }
  if (!salud.disponible) {
    return destino == AppRoutes.sinServidor ? null : AppRoutes.sinServidor;
  }

  // Mientras se restaura la sesión guardada no se decide nada todavía.
  if (sesion.cargando) {
    return destino == AppRoutes.cargando ? null : AppRoutes.cargando;
  }

  final usuario = sesion.usuario;
  if (usuario == null) {
    return destino == AppRoutes.login ? null : AppRoutes.login;
  }

  // El usuario debe cambiar su clave antes de usar la app.
  if (usuario.estado.requiereCambioDeClave) {
    return destino == AppRoutes.cambiarClave ? null : AppRoutes.cambiarClave;
  }

  // Quien ya cambió la clave no vuelve a esa pantalla, y el login y la
  // pantalla de carga no tienen sentido con sesión activa.
  const rutasSinSesion = {
    AppRoutes.cargando,
    AppRoutes.sinServidor,
    AppRoutes.login,
    AppRoutes.cambiarClave,
  };
  if (rutasSinSesion.contains(destino)) {
    return switch (usuario.rol) {
      RolUsuario.guardia => AppRoutes.movimientos,
      // Un rol no permitido no debería llegar aquí: el caso de uso del login
      // lo rechaza y limpia la sesión. Por si acaso, vuelve al login.
      RolUsuario.administrador => AppRoutes.login,
    };
  }

  return null;
}
