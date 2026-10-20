import 'package:logging/logging.dart';

import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../data/services/ubicacion_service.dart';
import '../models/movimiento_model.dart';
import '../models/tipo_movimiento.dart';
import '../models/ubicacion_model.dart';

/// Caso de uso del registro de un movimiento. Existe porque combina dos
/// fuentes: la ubicación del dispositivo y la api.
///
/// 1. valida que el QR traiga texto;
/// 2. intenta obtener las coordenadas (**mejor esfuerzo**: si el guardia negó
///    el permiso o el gps falla, se registra sin ellas, como dice el contrato);
/// 3. `POST /movimientos` con `data`, `tipo` y, si las hay, `latitud` y
///    `longitud`.
class RegistrarMovimientoUseCase {
  RegistrarMovimientoUseCase({
    required MovimientoRepository movimientoRepository,
    required UbicacionService ubicacionService,
  }) : _movimientoRepository = movimientoRepository,
       _ubicacionService = ubicacionService;

  /// Mensaje cuando el QR no trae contenido utilizable.
  static const mensajeQrVacio = 'El código QR no contiene datos del vehículo';

  final MovimientoRepository _movimientoRepository;
  final UbicacionService _ubicacionService;
  final Logger _log = Logger('RegistrarMovimientoUseCase');

  Future<Result<MovimientoModel>> ejecutar({
    required String data,
    required TipoMovimiento tipo,
  }) async {
    final contenido = data.trim();
    if (contenido.isEmpty) {
      return Result.error(const ApiException(mensajeQrVacio));
    }

    final ubicacion = await _obtenerUbicacionSiSePuede();

    return _movimientoRepository.registrar(
      data: contenido,
      tipo: tipo,
      ubicacion: ubicacion,
    );
  }

  /// La ubicación nunca bloquea el registro: si no se puede obtener se deja en
  /// `null` y se anota en el log.
  Future<UbicacionModel?> _obtenerUbicacionSiSePuede() async {
    final resultado = await _ubicacionService.obtenerUbicacion();
    switch (resultado) {
      case Ok<UbicacionModel>():
        return resultado.value;
      case Error<UbicacionModel>():
        _log.info(
          'El movimiento se registrará sin coordenadas: ${resultado.error}',
        );
        return null;
    }
  }
}
