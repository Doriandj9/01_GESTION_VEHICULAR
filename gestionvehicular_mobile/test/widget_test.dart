import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:gestionvehicular_mobile/core/themes/theme.dart';
import 'package:gestionvehicular_mobile/core/utils/result.dart';
import 'package:gestionvehicular_mobile/domain/models/sesion/usuario_model.dart';
import 'package:gestionvehicular_mobile/domain/stores/sesion_store.dart';
import 'package:gestionvehicular_mobile/inicio_sesion/data/repositories/autenticacion_repository.dart';
import 'package:gestionvehicular_mobile/inicio_sesion/domain/use_cases/iniciar_sesion_use_case.dart';
import 'package:gestionvehicular_mobile/inicio_sesion/domain/validaciones_inicio_sesion.dart';
import 'package:gestionvehicular_mobile/inicio_sesion/ui/viewmodels/inicio_sesion_viewmodel.dart';
import 'package:gestionvehicular_mobile/acceso_biometrico/data/services/biometria_service.dart';
import 'package:gestionvehicular_mobile/acceso_biometrico/domain/use_cases/iniciar_sesion_biometrica_use_case.dart';
import 'package:gestionvehicular_mobile/inicio_sesion/ui/widgets/inicio_sesion_screen.dart';

import 'dobles/acceso_biometrico_falso.dart';

class _AutenticacionRepositoryFalso extends Mock
    implements AutenticacionRepository {}

void main() {
  group('ValidacionesInicioSesion', () {
    test('rechaza un correo vacío o con formato inválido', () {
      expect(ValidacionesInicioSesion.correo(''), 'Ingrese su correo');
      expect(ValidacionesInicioSesion.correo('   '), 'Ingrese su correo');
      expect(
        ValidacionesInicioSesion.correo('guardia'),
        'Ingrese un correo válido',
      );
    });

    test('acepta un correo válido con espacios alrededor', () {
      expect(
        ValidacionesInicioSesion.correo(' guardia@gadmjs.gob.ec '),
        isNull,
      );
    });

    test('exige una contraseña no vacía', () {
      expect(ValidacionesInicioSesion.password(''), 'Ingrese su contraseña');
      expect(ValidacionesInicioSesion.password('secreta'), isNull);
    });
  });

  group('InicioSesionScreen', () {
    late _AutenticacionRepositoryFalso repositorio;
    late SesionStore sesionStore;
    late AccesoBiometricoFalso accesoBiometrico;
    late InicioSesionViewmodel viewModel;

    /// Construye el viewmodel del login. Por defecto el dispositivo **no**
    /// recuerda a nadie: el icono de la huella no debe aparecer.
    InicioSesionViewmodel construirViewModel() {
      return InicioSesionViewmodel(
        iniciarSesionUseCase: IniciarSesionUseCase(
          autenticacionRepository: repositorio,
          accesoBiometricoRepository: accesoBiometrico,
          sesionStore: sesionStore,
        ),
        iniciarSesionBiometricaUseCase: IniciarSesionBiometricaUseCase(
          accesoBiometricoRepository: accesoBiometrico,
          autenticacionRepository: repositorio,
          sesionStore: sesionStore,
        ),
        accesoBiometricoRepository: accesoBiometrico,
      );
    }

    setUp(() {
      repositorio = _AutenticacionRepositoryFalso();
      sesionStore = SesionStore(autenticacionRepository: repositorio);
      accesoBiometrico = AccesoBiometricoFalso();
      viewModel = construirViewModel();
    });

    Widget construirApp() {
      return ChangeNotifierProvider.value(
        value: sesionStore,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: InicioSesionScreen(viewModel: viewModel),
        ),
      );
    }

    testWidgets('muestra el formulario de credenciales', (tester) async {
      await tester.pumpWidget(construirApp());

      expect(find.text('Gestión Vehicular'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Ingresar'), findsOneWidget);
    });

    testWidgets('sin credencial guardada no ofrece la huella', (tester) async {
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fingerprint), findsNothing);
      expect(find.text('o ingrese con su huella'), findsNothing);
    });

    testWidgets('con credencial vigente ofrece la huella y el correo', (
      tester,
    ) async {
      accesoBiometrico.credencial = credencialDePrueba();
      viewModel = construirViewModel();

      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      expect(find.text('guardia@gadmjs.gob.ec'), findsOneWidget);
    });

    testWidgets('si el dispositivo no tiene biometría no la ofrece', (
      tester,
    ) async {
      accesoBiometrico
        ..credencial = credencialDePrueba()
        ..estado = EstadoBiometria.sinRegistro;
      viewModel = construirViewModel();

      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fingerprint), findsNothing);
    });

    testWidgets('al pulsar la huella refresca la sesión', (tester) async {
      accesoBiometrico.credencial = credencialDePrueba();
      viewModel = construirViewModel();
      when(() => repositorio.refrescarSesion(any()))
          .thenAnswer((_) async => const Result.ok(null));
      when(() => repositorio.obtenerUsuarioActual()).thenAnswer(
        (_) async => Result.ok(
          UsuarioModel.fromJson(const {
            'codUsuarios': 7,
            'nombres': 'Guardia de prueba',
            'correo': 'guardia@gadmjs.gob.ec',
            'estado': 'ACTIVO',
            'rol': 'GUARDIA',
          }),
        ),
      );

      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();
      // En el alto del test el icono cae fuera de pantalla: hay que acercarlo.
      await tester.ensureVisible(find.byIcon(Icons.fingerprint));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pumpAndSettle();

      verify(() => repositorio.refrescarSesion('RT-GUARDADO')).called(1);
      expect(sesionStore.usuario?.correo, 'guardia@gadmjs.gob.ec');
      // El éxito no abre diálogo: redirige el router.
      expect(find.text('No se pudo ingresar'), findsNothing);
    });

    testWidgets('valida en el front antes de llamar a la api', (tester) async {
      await tester.pumpWidget(construirApp());

      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese su correo'), findsOneWidget);
      expect(find.text('Ingrese su contraseña'), findsOneWidget);
      verifyNever(
        () => repositorio.autenticar(
          correo: any(named: 'correo'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('con credenciales válidas ejecuta el inicio de sesión', (
      tester,
    ) async {
      when(
        () => repositorio.autenticar(
          correo: any(named: 'correo'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));
      when(() => repositorio.obtenerUsuarioActual())
          .thenAnswer((_) async => Result.error(Exception('Sin detalle')));
      when(() => repositorio.limpiarTokens()).thenAnswer((_) async {});

      await tester.pumpWidget(construirApp());
      await tester.enterText(
        find.byType(TextFormField).first,
        'guardia@gadmjs.gob.ec',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Secreta123*');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      verify(
        () => repositorio.autenticar(
          correo: 'guardia@gadmjs.gob.ec',
          password: 'Secreta123*',
        ),
      ).called(1);
      // El detalle falló: no hay sesión y el error se informa en un diálogo.
      expect(sesionStore.usuario, isNull);
      expect(find.text('No se pudo iniciar sesión'), findsOneWidget);
    });

    testWidgets('rechaza a un usuario que no es guardia', (tester) async {
      when(
        () => repositorio.autenticar(
          correo: any(named: 'correo'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));
      when(() => repositorio.obtenerUsuarioActual()).thenAnswer(
        (_) async => Result.ok(
          UsuarioModel.fromJson(const {
            'codUsuarios': 1,
            'nombres': 'Admin de prueba',
            'correo': 'admin@gadmjs.gob.ec',
            'estado': 'ACTIVO',
            'rol': 'ADMINISTRADOR',
          }),
        ),
      );
      when(() => repositorio.limpiarTokens()).thenAnswer((_) async {});

      await tester.pumpWidget(construirApp());
      await tester.enterText(
        find.byType(TextFormField).first,
        'admin@gadmjs.gob.ec',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Secreta123*');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(
        find.text(IniciarSesionUseCase.mensajeRolNoPermitido),
        findsOneWidget,
      );
      expect(sesionStore.usuario, isNull);
      verify(() => repositorio.limpiarTokens()).called(1);
    });
  });
}
