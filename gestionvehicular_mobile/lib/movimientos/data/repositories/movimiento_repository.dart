import '../../../core/utils/result.dart';
import '../../domain/models/movimiento_model.dart';
import '../../domain/models/movimiento_registrado_model.dart';
import '../../domain/models/tipo_movimiento.dart';
import '../../domain/models/ubicacion_model.dart';

/// Contrato del registro de movimientos. La ui y los casos de uso dependen de
/// esta interfaz, nunca del `ApiClient`.
abstract class MovimientoRepository {
  /// `POST /movimientos`. [data] es el texto leído del QR del vehículo.
  /// [ubicacion] es opcional: si es `null` el movimiento se registra sin
  /// coordenadas.
  Future<Result<MovimientoModel>> registrar({
    required String data,
    required TipoMovimiento tipo,
    UbicacionModel? ubicacion,
  });

  /// `GET /movimientos/usuario`: movimientos que **registró** [codUsuario]
  /// desde [desde] (inclusive), de más reciente a más antiguo.
  Future<Result<List<MovimientoRegistradoModel>>> listarPorUsuario({
    required int codUsuario,
    required DateTime desde,
  });
}
