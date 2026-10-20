import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:gestionvehicular_mobile/cambiar_clave/domain/reglas_clave.dart';
import 'package:gestionvehicular_mobile/cambiar_clave/domain/use_cases/cambiar_clave_use_case.dart';
import 'package:gestionvehicular_mobile/cambiar_clave/ui/viewmodels/cambiar_clave_viewmodel.dart';
import 'package:gestionvehicular_mobile/cambiar_clave/ui/widgets/cambiar_clave_screen.dart';
import 'package:gestionvehicular_mobile/core/themes/theme.dart';
import 'package:gestionvehicular_mobile/core/utils/result.dart';
import 'package:gestionvehicular_mobile/domain/models/sesion/usuario_model.dart';
import 'package:gestionvehicular_mobile/domain/stores/sesion_store.dart';
import 'package:gestionvehicular_mobile/inicio_sesion/data/repositories/autenticacion_repository.dart';

import 'dobles/acceso_biometrico_falso.dart';

class _AutenticacionRepositoryFalso extends Mock
    implements AutenticacionRepository {}

UsuarioModel _usuario(String estado) => UsuarioModel.fromJson({
  'codUsuarios': 7,
  'nombres': 'Guardia de prueba',
  'correo': 'guardia@gadmjs.gob.ec',
  'estado': estado,
  'rol': 'GUARDIA',
});

void main() {
  group('reglas de la clave', () {
    test('exige las seis métricas, igual que la web', () {
      final reglas = evaluarClave('abc');
      expect(reglas, hasLength(6));
      expect(reglas.every((regla) => regla.cumple), isFalse);
    });

    test('una clave completa cumple todas las métricas', () {
      expect(claveEsValida('Secreta123*'), isTrue);
      expect(fortalezaClave('Secreta123*'), 3);
    });

    test('rechaza claves cortas, sin especial o con espacios', () {
      expect(claveEsValida('Abc123*'), isFalse, reason: 'menos de 8');
      expect(claveEsValida('Secreta123'), isFalse, reason: 'sin especial');
      expect(claveEsValida('Secreta 123*'), isFalse, reason: 'con espacio');
      expect(claveEsValida('secreta123*'), isFalse, reason: 'sin mayúscula');
      expect(claveEsValida('SECRETA123*'), isFalse, reason: 'sin minúscula');
      expect(claveEsValida('Secretaxx*'), isFalse, reason: 'sin número');
    });
  });

  group('CambiarClaveUseCase', () {
    late _AutenticacionRepositoryFalso repositorio;
    late SesionStore sesionStore;
    late AccesoBiometricoFalso accesoBiometrico;
    late CambiarClaveUseCase useCase;

    setUp(() {
      repositorio = _AutenticacionRepositoryFalso();
      sesionStore = SesionStore(autenticacionRepository: repositorio);
      sesionStore.establecerUsuario(_usuario('INICIAL'));
      accesoBiometrico = AccesoBiometricoFalso();
      useCase = CambiarClaveUseCase(
        autenticacionRepository: repositorio,
        accesoBiometricoRepository: accesoBiometrico,
        sesionStore: sesionStore,
      );
    });

    test('no llama a la api si la clave nueva es débil', () async {
      final resultado = await useCase.ejecutar(
        claveActual: 'Inicial123*',
        claveNueva: 'corta',
      );

      expect(resultado, isA<Error>());
      verifyNever(
        () => repositorio.cambiarClave(
          correo: any(named: 'correo'),
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    test('no llama a la api si la clave nueva es igual a la actual', () async {
      final resultado = await useCase.ejecutar(
        claveActual: 'Secreta123*',
        claveNueva: 'Secreta123*',
      );

      expect(resultado, isA<Error>());
      verifyNever(
        () => repositorio.cambiarClave(
          correo: any(named: 'correo'),
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    test(
      'cambia la clave y relee el usuario, que deja de ser INICIAL',
      () async {
        when(
          () => repositorio.cambiarClave(
            correo: any(named: 'correo'),
            oldPassword: any(named: 'oldPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenAnswer((_) async => const Result.ok(null));
        when(() => repositorio.obtenerUsuarioActual())
            .thenAnswer((_) async => Result.ok(_usuario('ACTIVO')));

        final resultado = await useCase.ejecutar(
          claveActual: 'Inicial123*',
          claveNueva: 'Secreta123*',
        );

        expect(resultado, isA<Ok<UsuarioModel>>());
        // El correo lo toma de la sesión, no se le pide al usuario.
        verify(
          () => repositorio.cambiarClave(
            correo: 'guardia@gadmjs.gob.ec',
            oldPassword: 'Inicial123*',
            newPassword: 'Secreta123*',
          ),
        ).called(1);
        expect(sesionStore.usuario?.estado.requiereCambioDeClave, isFalse);
      },
    );

    test('si no se puede releer el usuario, descarta la sesión', () async {
      when(
        () => repositorio.cambiarClave(
          correo: any(named: 'correo'),
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));
      when(() => repositorio.obtenerUsuarioActual())
          .thenAnswer((_) async => Result.error(Exception('Sin detalle')));
      when(() => repositorio.limpiarTokens()).thenAnswer((_) async {});

      final resultado = await useCase.ejecutar(
        claveActual: 'Inicial123*',
        claveNueva: 'Secreta123*',
      );

      expect(resultado, isA<Error>());
      expect(sesionStore.usuario, isNull);
      expect(sesionStore.sesionExpirada, isTrue);
      verify(() => repositorio.limpiarTokens()).called(1);
    });
  });

  group('CambiarClaveScreen', () {
    late _AutenticacionRepositoryFalso repositorio;
    late SesionStore sesionStore;
    late CambiarClaveViewmodel viewModel;

    setUp(() {
      repositorio = _AutenticacionRepositoryFalso();
      sesionStore = SesionStore(autenticacionRepository: repositorio);
      sesionStore.establecerUsuario(_usuario('INICIAL'));
      viewModel = CambiarClaveViewmodel(
        cambiarClaveUseCase: CambiarClaveUseCase(
          accesoBiometricoRepository: AccesoBiometricoFalso(),
          autenticacionRepository: repositorio,
          sesionStore: sesionStore,
        ),
      );
    });

    Widget construirApp() {
      return ChangeNotifierProvider.value(
        value: sesionStore,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: CambiarClaveScreen(viewModel: viewModel),
        ),
      );
    }

    testWidgets('muestra el aviso de clave inicial y las métricas', (
      tester,
    ) async {
      await tester.pumpWidget(construirApp());

      expect(find.text('Cambie su clave'), findsOneWidget);
      expect(
        find.text(
          'Su cuenta usa una clave inicial. Debe cambiarla para continuar.',
        ),
        findsOneWidget,
      );
      expect(find.text('Al menos 8 caracteres'), findsOneWidget);
      expect(find.text('Distinta de la clave actual'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('el botón solo se habilita cuando todo está correcto', (
      tester,
    ) async {
      await tester.pumpWidget(construirApp());

      final boton = find.widgetWithText(FilledButton, 'Cambiar clave');
      expect(tester.widget<FilledButton>(boton).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(0), 'Inicial123*');
      await tester.enterText(find.byType(TextField).at(1), 'Secreta123*');
      await tester.pump();
      // Falta la confirmación: sigue deshabilitado.
      expect(tester.widget<FilledButton>(boton).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(2), 'Secreta123*');
      await tester.pump();
      expect(tester.widget<FilledButton>(boton).onPressed, isNotNull);
    });

    testWidgets('avisa cuando las claves nuevas no coinciden', (tester) async {
      await tester.pumpWidget(construirApp());

      await tester.enterText(find.byType(TextField).at(1), 'Secreta123*');
      await tester.enterText(find.byType(TextField).at(2), 'Otra123*');
      await tester.pump();

      expect(find.text('Las claves no coinciden.'), findsOneWidget);
    });

    testWidgets('un error de la api se informa y limpia los campos', (
      tester,
    ) async {
      when(
        () => repositorio.cambiarClave(
          correo: any(named: 'correo'),
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer(
        (_) async => Result.error(Exception('Clave actual incorrecta')),
      );

      await tester.pumpWidget(construirApp());
      await tester.enterText(find.byType(TextField).at(0), 'Mala123*');
      await tester.enterText(find.byType(TextField).at(1), 'Secreta123*');
      await tester.enterText(find.byType(TextField).at(2), 'Secreta123*');
      await tester.pump();
      // El formulario es más alto que la pantalla de prueba: hay que traer el
      // botón a la vista antes de pulsarlo.
      final boton = find.widgetWithText(FilledButton, 'Cambiar clave');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.text('No se pudo cambiar la clave'), findsOneWidget);
      expect(find.text('Clave actual incorrecta'), findsOneWidget);
      expect(viewModel.claveActual, isEmpty);
      expect(viewModel.claveNueva, isEmpty);
      expect(viewModel.claveRepetida, isEmpty);
    });
  });
}
