import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gestionvehicular_mobile/core/themes/theme.dart';
import 'package:gestionvehicular_mobile/core/utils/api_errors.dart';
import 'package:gestionvehicular_mobile/core/utils/result.dart';
import 'package:gestionvehicular_mobile/salud_servidor/data/models/salud_api_model.dart';
import 'package:gestionvehicular_mobile/salud_servidor/data/repositories/salud_repository.dart';
import 'package:gestionvehicular_mobile/salud_servidor/domain/models/estado_salud.dart';
import 'package:gestionvehicular_mobile/salud_servidor/domain/models/salud_servidor_model.dart';
import 'package:gestionvehicular_mobile/salud_servidor/domain/stores/salud_store.dart';
import 'package:gestionvehicular_mobile/salud_servidor/ui/widgets/sin_servidor_screen.dart';

/// Doble del sondeo, escrito a mano: devuelve lo que se le indique y cuenta
/// cuántas veces se le preguntó.
class _SaludRepositoryFalso extends SaludRepository {
  _SaludRepositoryFalso(this.respuesta);

  Result<SaludServidorModel> respuesta;
  int consultas = 0;

  @override
  Future<Result<SaludServidorModel>> consultar() async {
    consultas++;
    return respuesta;
  }
}

Result<SaludServidorModel> _arriba() => const Result.ok(
  SaludServidorModel(estado: EstadoSalud.up, grupos: ['liveness', 'readiness']),
);

void main() {
  group('SaludApiModel', () {
    test('lee la respuesta real del actuator', () {
      final dto = SaludApiModel.fromJson(const {
        'groups': ['liveness', 'readiness'],
        'status': 'UP',
      });

      expect(dto.status, 'UP');
      expect(dto.groups, ['liveness', 'readiness']);
    });

    test('tolera una respuesta sin grupos', () {
      final dto = SaludApiModel.fromJson(const {'status': 'DOWN'});

      expect(dto.status, 'DOWN');
      expect(dto.groups, isEmpty);
    });
  });

  group('EstadoSalud', () {
    test('traduce los estados del actuator', () {
      expect(EstadoSalud.desdeApi('UP'), EstadoSalud.up);
      expect(EstadoSalud.desdeApi('down'), EstadoSalud.down);
      expect(
        EstadoSalud.desdeApi('OUT_OF_SERVICE'),
        EstadoSalud.fueraDeServicio,
      );
    });

    test('un estado desconocido no se da por bueno', () {
      expect(EstadoSalud.desdeApi('CUALQUIERA'), EstadoSalud.desconocido);
      expect(EstadoSalud.desdeApi(''), EstadoSalud.desconocido);
      expect(EstadoSalud.desconocido.estaArriba, isFalse);
    });
  });

  group('SaludStore', () {
    test('con UP queda disponible y restaura la sesión', () async {
      final repositorio = _SaludRepositoryFalso(_arriba());
      final store = SaludStore(saludRepository: repositorio);
      var restauraciones = 0;
      store.alEstarDisponible = () async => restauraciones++;

      await store.verificar();

      expect(store.disponible, isTrue);
      expect(store.verificando, isFalse);
      expect(store.detalles, isEmpty);
      expect(restauraciones, 1);
    });

    test('con DOWN queda caído y no restaura la sesión', () async {
      final repositorio = _SaludRepositoryFalso(
        const Result.ok(SaludServidorModel(estado: EstadoSalud.down)),
      );
      final store = SaludStore(saludRepository: repositorio);
      var restauraciones = 0;
      store.alEstarDisponible = () async => restauraciones++;

      await store.verificar();

      expect(store.disponible, isFalse);
      expect(store.mensaje, SaludStore.mensajeConFallas);
      expect(store.detalles.any((d) => d.contains('DOWN')), isTrue);
      // Esto es lo importante: un servidor caído no debe borrar los tokens.
      expect(restauraciones, 0);
    });

    test('sin respuesta avisa que no se encuentra y da el detalle', () async {
      final repositorio = _SaludRepositoryFalso(
        Result.error(const ApiException(ApiErrors.mensajeSinConexion)),
      );
      final store = SaludStore(saludRepository: repositorio);

      await store.verificar();

      expect(store.disponible, isFalse);
      expect(store.mensaje, SaludStore.mensajeNoSeEncuentra);
      expect(store.salud, isNull);
      expect(
        store.detalles.any((d) => d.contains(ApiErrors.mensajeSinConexion)),
        isTrue,
      );
      // El detalle siempre dice qué url se sondeó.
      expect(store.detalles.first, contains('/actuator/health'));
    });

    test('reintentar vuelve a preguntar y puede recuperarse', () async {
      final repositorio = _SaludRepositoryFalso(
        Result.error(const ApiException(ApiErrors.mensajeSinConexion)),
      );
      final store = SaludStore(saludRepository: repositorio);

      await store.verificar();
      expect(store.disponible, isFalse);

      repositorio.respuesta = _arriba();
      await store.verificar();

      expect(store.disponible, isTrue);
      expect(repositorio.consultas, 2);
    });
  });

  group('SinServidorScreen', () {
    testWidgets('muestra el mensaje, los detalles y el reintento', (
      tester,
    ) async {
      final repositorio = _SaludRepositoryFalso(
        Result.error(const ApiException(ApiErrors.mensajeSinConexion)),
      );
      final store = SaludStore(saludRepository: repositorio);
      await store.verificar();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: store,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: SinServidorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Servidor no disponible'), findsOneWidget);
      expect(find.text(SaludStore.mensajeNoSeEncuentra), findsOneWidget);
      expect(find.text('Detalles'), findsOneWidget);
      expect(find.textContaining(ApiErrors.mensajeSinConexion), findsOneWidget);

      repositorio.respuesta = _arriba();
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(store.disponible, isTrue);
      expect(repositorio.consultas, 2);
    });
  });
}
