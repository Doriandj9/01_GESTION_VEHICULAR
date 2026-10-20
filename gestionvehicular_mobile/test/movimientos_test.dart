import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:gestionvehicular_mobile/core/themes/theme.dart';
import 'package:gestionvehicular_mobile/core/utils/api_errors.dart';
import 'package:gestionvehicular_mobile/core/utils/result.dart';
import 'package:gestionvehicular_mobile/domain/stores/sesion_store.dart';
import 'package:gestionvehicular_mobile/domain/models/sesion/usuario_model.dart';
import 'package:gestionvehicular_mobile/inicio_sesion/data/repositories/autenticacion_repository.dart';
import 'package:gestionvehicular_mobile/movimientos/data/repositories/movimiento_repository.dart';
import 'package:gestionvehicular_mobile/movimientos/data/services/ubicacion_service.dart';
import 'package:gestionvehicular_mobile/movimientos/domain/models/movimiento_model.dart';
import 'package:gestionvehicular_mobile/movimientos/domain/models/tipo_movimiento.dart';
import 'package:gestionvehicular_mobile/movimientos/domain/models/ubicacion_model.dart';
import 'package:gestionvehicular_mobile/movimientos/domain/models/movimiento_registrado_model.dart';
import 'package:gestionvehicular_mobile/movimientos/domain/use_cases/listar_mis_movimientos_use_case.dart';
import 'package:gestionvehicular_mobile/movimientos/domain/use_cases/registrar_movimiento_use_case.dart';
import 'package:gestionvehicular_mobile/movimientos/ui/viewmodels/movimientos_viewmodel.dart';
import 'package:gestionvehicular_mobile/movimientos/ui/widgets/movimientos_screen.dart';

class _MovimientoRepositoryFalso extends Mock implements MovimientoRepository {}

class _UbicacionServiceFalso extends Mock implements UbicacionService {}

class _AutenticacionRepositoryFalso extends Mock
    implements AutenticacionRepository {}

const _ubicacion = UbicacionModel(latitud: -0.3321, longitud: -76.8701);

MovimientoModel _movimiento(TipoMovimiento tipo, {UbicacionModel? ubicacion}) =>
    MovimientoModel(
      registro: DateTime(2026, 10, 19, 8, 30),
      tipo: tipo,
      ubicacion: ubicacion,
    );

MovimientoRegistradoModel _registrado(
  TipoMovimiento tipo, {
  String placa = 'ABC-1234',
  int hora = 8,
}) => MovimientoRegistradoModel(
  fecha: DateTime(2026, 10, 19, hora, 15),
  tipo: tipo,
  placa: placa,
  conductor: 'Juan Perez',
);

void main() {
  setUpAll(() {
    registerFallbackValue(TipoMovimiento.entrada);
    registerFallbackValue(DateTime(2026));
  });

  group('RegistrarMovimientoUseCase', () {
    late _MovimientoRepositoryFalso repositorio;
    late _UbicacionServiceFalso ubicacion;
    late RegistrarMovimientoUseCase useCase;

    setUp(() {
      repositorio = _MovimientoRepositoryFalso();
      ubicacion = _UbicacionServiceFalso();
      useCase = RegistrarMovimientoUseCase(
        movimientoRepository: repositorio,
        ubicacionService: ubicacion,
      );
    });

    test('rechaza un QR vacío sin llamar a la api', () async {
      final resultado = await useCase.ejecutar(
        data: '   ',
        tipo: TipoMovimiento.entrada,
      );

      expect(resultado, isA<Error>());
      verifyNever(
        () => repositorio.registrar(
          data: any(named: 'data'),
          tipo: any(named: 'tipo'),
          ubicacion: any(named: 'ubicacion'),
        ),
      );
    });

    test('registra con las coordenadas cuando hay ubicación', () async {
      when(() => ubicacion.obtenerUbicacion())
          .thenAnswer((_) async => const Result.ok(_ubicacion));
      when(
        () => repositorio.registrar(
          data: any(named: 'data'),
          tipo: any(named: 'tipo'),
          ubicacion: any(named: 'ubicacion'),
        ),
      ).thenAnswer(
        (_) async => Result.ok(
          _movimiento(TipoMovimiento.salida, ubicacion: _ubicacion),
        ),
      );

      final resultado = await useCase.ejecutar(
        data: '  jwt-del-qr  ',
        tipo: TipoMovimiento.salida,
      );

      expect(resultado, isA<Ok<MovimientoModel>>());
      // El texto del QR viaja recortado y las coordenadas se adjuntan.
      verify(
        () => repositorio.registrar(
          data: 'jwt-del-qr',
          tipo: TipoMovimiento.salida,
          ubicacion: _ubicacion,
        ),
      ).called(1);
    });

    test('registra sin coordenadas si la ubicación falla', () async {
      when(() => ubicacion.obtenerUbicacion()).thenAnswer(
        (_) async => Result.error(
          const UbicacionException(
            MotivoSinUbicacion.permisoNegado,
            'Sin permiso',
          ),
        ),
      );
      when(
        () => repositorio.registrar(
          data: any(named: 'data'),
          tipo: any(named: 'tipo'),
          ubicacion: any(named: 'ubicacion'),
        ),
      ).thenAnswer((_) async => Result.ok(_movimiento(TipoMovimiento.entrada)));

      final resultado = await useCase.ejecutar(
        data: 'jwt-del-qr',
        tipo: TipoMovimiento.entrada,
      );

      // La ubicación nunca bloquea el registro.
      expect(resultado, isA<Ok<MovimientoModel>>());
      verify(
        () => repositorio.registrar(
          data: 'jwt-del-qr',
          tipo: TipoMovimiento.entrada,
          ubicacion: null,
        ),
      ).called(1);
    });

    test('propaga el error de la api', () async {
      when(() => ubicacion.obtenerUbicacion())
          .thenAnswer((_) async => const Result.ok(_ubicacion));
      when(
        () => repositorio.registrar(
          data: any(named: 'data'),
          tipo: any(named: 'tipo'),
          ubicacion: any(named: 'ubicacion'),
        ),
      ).thenAnswer(
        (_) async =>
            Result.error(const ApiException('El movimiento fue rechazado')),
      );

      final resultado = await useCase.ejecutar(
        data: 'jwt-del-qr',
        tipo: TipoMovimiento.entrada,
      );

      expect(resultado, isA<Error>());
    });
  });

  group('MovimientosScreen', () {
    late _MovimientoRepositoryFalso repositorio;
    late _UbicacionServiceFalso ubicacion;
    late SesionStore sesionStore;
    late MovimientosViewmodel viewModel;

    setUp(() {
      repositorio = _MovimientoRepositoryFalso();
      ubicacion = _UbicacionServiceFalso();
      sesionStore = SesionStore(
        autenticacionRepository: _AutenticacionRepositoryFalso(),
      );
      sesionStore.establecerUsuario(
        UsuarioModel.fromJson(const {
          'codUsuarios': 7,
          'nombres': 'Guardia de prueba',
          'correo': 'guardia@gadmjs.gob.ec',
          'estado': 'ACTIVO',
          'rol': 'GUARDIA',
        }),
      );
    });

    /// Por defecto la lista llega vacía: cada prueba la ajusta si le importa.
    void listaDevuelve(List<MovimientoRegistradoModel> movimientos) {
      when(
        () => repositorio.listarPorUsuario(
          codUsuario: any(named: 'codUsuario'),
          desde: any(named: 'desde'),
        ),
      ).thenAnswer((_) async => Result.ok(movimientos));
    }

    void construirViewmodel({List<MovimientoRegistradoModel>? lista}) {
      listaDevuelve(lista ?? const []);
      viewModel = MovimientosViewmodel(
        registrarMovimientoUseCase: RegistrarMovimientoUseCase(
          movimientoRepository: repositorio,
          ubicacionService: ubicacion,
        ),
        listarMisMovimientosUseCase: ListarMisMovimientosUseCase(
          movimientoRepository: repositorio,
          sesionStore: sesionStore,
        ),
        ubicacionService: ubicacion,
      );
    }

    Widget construirApp() {
      return ChangeNotifierProvider.value(
        value: sesionStore,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MovimientosScreen(viewModel: viewModel),
        ),
      );
    }

    testWidgets('pide el permiso de ubicación al abrir la pantalla', (
      tester,
    ) async {
      when(() => ubicacion.solicitarPermiso())
          .thenAnswer((_) async => EstadoPermisoUbicacion.concedido);

      construirViewmodel();
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      verify(() => ubicacion.solicitarPermiso()).called(1);
      expect(
        find.text('El movimiento se registrará con su ubicación.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra las dos acciones, salida primero', (tester) async {
      when(() => ubicacion.solicitarPermiso())
          .thenAnswer((_) async => EstadoPermisoUbicacion.concedido);

      construirViewmodel();
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      expect(find.text('SALIDA'), findsOneWidget);
      expect(find.text('ENTRADA'), findsOneWidget);
      // El orden en pantalla: la salida va arriba de la entrada.
      final salida = tester.getTopLeft(find.text('SALIDA'));
      final entrada = tester.getTopLeft(find.text('ENTRADA'));
      expect(salida.dy, lessThan(entrada.dy));
    });

    testWidgets('avisa que registrará sin coordenadas si se niega el permiso', (
      tester,
    ) async {
      when(() => ubicacion.solicitarPermiso())
          .thenAnswer((_) async => EstadoPermisoUbicacion.negado);

      construirViewmodel();
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('se registrará sin coordenadas'),
        findsOneWidget,
      );
      expect(find.text('Permitir ubicación'), findsOneWidget);
      expect(viewModel.registraraSinUbicacion, isTrue);
    });

    testWidgets('con el permiso negado para siempre ofrece los ajustes', (
      tester,
    ) async {
      when(() => ubicacion.solicitarPermiso())
          .thenAnswer((_) async => EstadoPermisoUbicacion.negadoParaSiempre);
      when(() => ubicacion.abrirAjustes()).thenAnswer((_) async {});

      construirViewmodel();
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      expect(find.text('Abrir ajustes'), findsOneWidget);
      await tester.tap(find.text('Abrir ajustes'));
      await tester.pumpAndSettle();

      verify(() => ubicacion.abrirAjustes()).called(1);
    });

    testWidgets('el éxito se informa con el diálogo global', (tester) async {
      when(() => ubicacion.solicitarPermiso())
          .thenAnswer((_) async => EstadoPermisoUbicacion.concedido);
      when(() => ubicacion.obtenerUbicacion())
          .thenAnswer((_) async => const Result.ok(_ubicacion));
      when(
        () => repositorio.registrar(
          data: any(named: 'data'),
          tipo: any(named: 'tipo'),
          ubicacion: any(named: 'ubicacion'),
        ),
      ).thenAnswer(
        (_) async => Result.ok(
          _movimiento(TipoMovimiento.salida, ubicacion: _ubicacion),
        ),
      );

      construirViewmodel(lista: [_registrado(TipoMovimiento.salida)]);
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      // Se simula el texto que devolvería el escáner, sin abrir la cámara.
      await viewModel.registrar.execute(('jwt-del-qr', TipoMovimiento.salida));
      await tester.pumpAndSettle();

      expect(find.text('Salida registrada'), findsOneWidget);
      expect(viewModel.movimientos, hasLength(1));
    });

    testWidgets('el error se informa con el diálogo global', (tester) async {
      when(() => ubicacion.solicitarPermiso())
          .thenAnswer((_) async => EstadoPermisoUbicacion.concedido);
      when(() => ubicacion.obtenerUbicacion())
          .thenAnswer((_) async => const Result.ok(_ubicacion));
      when(
        () => repositorio.registrar(
          data: any(named: 'data'),
          tipo: any(named: 'tipo'),
          ubicacion: any(named: 'ubicacion'),
        ),
      ).thenAnswer(
        (_) async => Result.error(
          const ApiException('El movimiento fue rechazado. Verifique el QR.'),
        ),
      );

      construirViewmodel();
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      await viewModel.registrar.execute(('jwt-del-qr', TipoMovimiento.entrada));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo registrar'), findsOneWidget);
      expect(
        find.text('El movimiento fue rechazado. Verifique el QR.'),
        findsOneWidget,
      );
      expect(viewModel.movimientos, isEmpty);
    });
    testWidgets(
      "el listado arranca filtrado en hoy y pide los movimientos del usuario de la sesion",
      (tester) async {
        when(() => ubicacion.solicitarPermiso())
            .thenAnswer((_) async => EstadoPermisoUbicacion.concedido);

        construirViewmodel(lista: [_registrado(TipoMovimiento.salida)]);
        await tester.pumpWidget(construirApp());
        await tester.pumpAndSettle();

        expect(find.text("Mis registros"), findsOneWidget);
        // El filtro por defecto es hoy, a las 00:00, y el cod sale de la sesion.
        expect(viewModel.filtraHoy, isTrue);
        final hoy = DateTime.now();
        verify(
          () => repositorio.listarPorUsuario(
            codUsuario: 7,
            desde: DateTime(hoy.year, hoy.month, hoy.day),
          ),
        ).called(1);
        expect(find.text("Hoy"), findsOneWidget);
        expect(find.text("ABC-1234"), findsOneWidget);
      },
    );

    testWidgets("avisa cuando no hay movimientos hoy", (tester) async {
      when(() => ubicacion.solicitarPermiso())
          .thenAnswer((_) async => EstadoPermisoUbicacion.concedido);

      construirViewmodel();
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      expect(
        find.text("Todavía no ha registrado movimientos hoy."),
        findsOneWidget,
      );
    });

    testWidgets("cambiar la fecha recarga la lista", (tester) async {
      when(() => ubicacion.solicitarPermiso())
          .thenAnswer((_) async => EstadoPermisoUbicacion.concedido);

      construirViewmodel();
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();

      await viewModel.cambiarFecha(DateTime(2026, 10, 1));
      await tester.pumpAndSettle();

      expect(viewModel.filtraHoy, isFalse);
      verify(
        () => repositorio.listarPorUsuario(
          codUsuario: 7,
          desde: DateTime(2026, 10, 1),
        ),
      ).called(1);
      expect(find.text("01/10/2026"), findsOneWidget);
    });

    testWidgets("tras registrar con exito la lista se recarga", (tester) async {
      when(() => ubicacion.solicitarPermiso())
          .thenAnswer((_) async => EstadoPermisoUbicacion.concedido);
      when(() => ubicacion.obtenerUbicacion())
          .thenAnswer((_) async => const Result.ok(_ubicacion));
      when(
        () => repositorio.registrar(
          data: any(named: "data"),
          tipo: any(named: "tipo"),
          ubicacion: any(named: "ubicacion"),
        ),
      ).thenAnswer(
        (_) async => Result.ok(
          _movimiento(TipoMovimiento.entrada, ubicacion: _ubicacion),
        ),
      );

      construirViewmodel();
      await tester.pumpWidget(construirApp());
      await tester.pumpAndSettle();
      // La primera carga ya ocurrio; ahora el registro debe provocar otra.
      listaDevuelve([_registrado(TipoMovimiento.entrada)]);

      await viewModel.registrar.execute(("jwt-del-qr", TipoMovimiento.entrada));
      await tester.pumpAndSettle();

      expect(viewModel.movimientos, hasLength(1));
      verify(
        () => repositorio.listarPorUsuario(
          codUsuario: any(named: "codUsuario"),
          desde: any(named: "desde"),
        ),
      ).called(2);
    });
  });
}
