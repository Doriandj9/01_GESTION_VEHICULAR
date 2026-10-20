import 'package:logging/logging.dart';

import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../data/services/api/api_client.dart';
import '../../domain/models/estado_movimiento.dart';
import '../../domain/models/movimiento_model.dart';
import '../../domain/models/movimiento_registrado_model.dart';
import '../../domain/models/tipo_movimiento.dart';
import '../../domain/models/ubicacion_model.dart';
import '../models/movimiento_api_model.dart';
import '../models/movimiento_registrado_api_model.dart';
import 'movimiento_repository.dart';

/// Implementación de [MovimientoRepository] sobre el `ApiClient`. Transforma el
/// DTO al modelo de dominio y aplica la regla del contrato: un 200 con
/// `estado: ERROR` es un rechazo de negocio, no un éxito.
class MovimientoRepositoryImpl extends MovimientoRepository {
  MovimientoRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  /// Mensaje con el que se informa un movimiento rechazado por la api.
  static const mensajeRechazado =
      'El movimiento fue rechazado. Verifique el código QR del vehículo.';

  final ApiClient _apiClient;
  final Logger _log = Logger('MovimientoRepositoryImpl');

  @override
  Future<Result<MovimientoModel>> registrar({
    required String data,
    required TipoMovimiento tipo,
    UbicacionModel? ubicacion,
  }) async {
    final resultado = await _apiClient.registrarMovimiento(
      data: data,
      tipo: tipo.valor,
      latitud: ubicacion?.latitud,
      longitud: ubicacion?.longitud,
    );
    switch (resultado) {
      case Error<MovimientoApiModel>():
        _log.warning('Fallo el registro del movimiento: ${resultado.error}');
        return Result.error(resultado.error);
      case Ok<MovimientoApiModel>():
    }

    final dto = resultado.value;
    final EstadoMovimiento estado;
    final DateTime registro;
    try {
      estado = EstadoMovimiento.desdeApi(dto.estado);
      registro = DateTime.parse(dto.registro);
    } on Exception catch (e) {
      _log.severe('Respuesta de movimiento no reconocida: $dto ($e)');
      return Result.error(const ApiException(ApiErrors.mensajeGenerico));
    } on ArgumentError catch (e) {
      _log.severe('Estado de movimiento no reconocido: $dto ($e)');
      return Result.error(const ApiException(ApiErrors.mensajeGenerico));
    }

    // Un 200 con estado ERROR es un rechazo de negocio, no un éxito.
    if (!estado.fueAceptado) {
      _log.warning('La api rechazó el movimiento: $dto');
      return Result.error(const ApiException(mensajeRechazado));
    }

    // El DTO no trae el tipo ni las coordenadas: se completan con lo enviado.
    return Result.ok(
      MovimientoModel(registro: registro, tipo: tipo, ubicacion: ubicacion),
    );
  }

  @override
  Future<Result<List<MovimientoRegistradoModel>>> listarPorUsuario({
    required int codUsuario,
    required DateTime desde,
  }) async {
    final resultado = await _apiClient.listarMovimientosPorUsuario(
      codUsuario: codUsuario,
      fecha: _fechaParaApi(desde),
    );
    switch (resultado) {
      case Error<List<MovimientoRegistradoApiModel>>():
        _log.warning('Fallo el listado de movimientos: ${resultado.error}');
        return Result.error(resultado.error);
      case Ok<List<MovimientoRegistradoApiModel>>():
    }

    // Un registro sin fecha o con un tipo desconocido no se puede mostrar: se
    // descarta y se anota, en vez de tumbar toda la lista.
    final movimientos = <MovimientoRegistradoModel>[];
    for (final dto in resultado.value) {
      final convertido = _aModelo(dto);
      if (convertido == null) {
        _log.warning('Movimiento descartado por datos incompletos: $dto');
        continue;
      }
      movimientos.add(convertido);
    }
    return Result.ok(movimientos);
  }

  MovimientoRegistradoModel? _aModelo(MovimientoRegistradoApiModel dto) {
    final fecha = dto.fechaRegistro;
    final tipo = dto.tipoMovimiento;
    if (fecha == null || tipo == null) return null;

    try {
      final latitud = dto.latitudRegistro;
      final longitud = dto.longitudRegistro;

      return MovimientoRegistradoModel(
        fecha: DateTime.parse(fecha),
        tipo: TipoMovimiento.desdeApi(tipo),
        codVehiculo: dto.codVehiculo,
        placa: dto.placa,
        conductor: dto.conductor,
        codUsuarioRegistro: dto.codUsuarioRegistro,
        nombreUsuarioRegistro: dto.nombreUsuarioRegistro,
        ubicacion: (latitud != null && longitud != null)
            ? UbicacionModel(latitud: latitud, longitud: longitud)
            : null,
      );
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  /// `yyyy-MM-ddTHH:mm:ss`, sin zona: el formato que lee el backend.
  String _fechaParaApi(DateTime fecha) {
    String dos(int valor) => valor.toString().padLeft(2, '0');

    return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
  }
}
