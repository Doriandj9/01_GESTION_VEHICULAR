import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'core/themes/theme.dart';
import 'domain/stores/sesion_store.dart';
import 'routing/router.dart';
import 'salud_servidor/domain/stores/salud_store.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((registro) {
    debugPrint(
      '${registro.level.name}: ${registro.loggerName}: ${registro.message}',
    );
  });

  runApp(
    MultiProvider(providers: appProviders, child: const GestionVehicularApp()),
  );
}

class GestionVehicularApp extends StatefulWidget {
  const GestionVehicularApp({super.key});

  @override
  State<GestionVehicularApp> createState() => _GestionVehicularAppState();
}

class _GestionVehicularAppState extends State<GestionVehicularApp> {
  /// El router se crea una sola vez: `refreshListenable` ya reacciona a los
  /// cambios del servidor y de la sesión, así que no debe reconstruirse en
  /// cada `build`.
  late final _router = crearRouter(
    context.read<SesionStore>(),
    context.read<SaludStore>(),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gestión Vehicular',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
