import 'package:logging/logging.dart';

import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../domain/stores/sesion_store.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../models/movimiento_registrado_model.dart';

/// Lista los movimientos que registró **el guardia de la sesión**, desde una
/// fecha.
///
/// Existe como caso de uso por una razón de seguridad: el parámetro `cod` de
/// `GET /movimientos/usuario` no está limitado al dueño del jwt, así que la api
/// aceptaría consultar los movimientos de otro usuario. Aquí el `codUsuarios`
/// se toma **siempre** del [SesionStore] y la ui no puede elegirlo.
class ListarMisMovimientosUseCase {
  ListarMisMovimientosUseCase({
    required MovimientoRepository movimientoRepository,
    required SesionStore sesionStore,
  }) : _movimientoRepository = movimientoRepository,
       _sesionStore = sesionStore;

  /// Mensaje cuando no hay usuario en sesión (no debería pasar en esta ruta).
  static const mensajeSinSesion = 'No hay una sesión activa';

  final MovimientoRepository _movimientoRepository;
  final SesionStore _sesionStore;
  final Logger _log = Logger('ListarMisMovimientosUseCase');

  Future<Result<List<MovimientoRegistradoModel>>> ejecutar({
    required DateTime desde,
  }) async {
    final codUsuario = _sesionStore.usuario?.codUsuarios;
    if (codUsuario == null) {
      return Result.error(const ApiException(mensajeSinSesion));
    }

    _log.info('Listando movimientos de $codUsuario desde $desde');
    return _movimientoRepository.listarPorUsuario(
      codUsuario: codUsuario,
      desde: desde,
    );
  }
}
