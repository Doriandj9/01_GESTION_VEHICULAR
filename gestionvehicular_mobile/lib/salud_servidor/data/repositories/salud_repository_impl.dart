import 'package:logging/logging.dart';

import '../../../core/utils/result.dart';
import '../../../data/services/api/api_client.dart';
import '../../domain/models/estado_salud.dart';
import '../../domain/models/salud_servidor_model.dart';
import '../models/salud_api_model.dart';
import 'salud_repository.dart';

/// Implementación de [SaludRepository] sobre el `ApiClient`. Transforma el dto
/// del actuator al modelo de dominio: la ui no ve un `SaludApiModel`.
class SaludRepositoryImpl extends SaludRepository {
  SaludRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final Logger _log = Logger('SaludRepositoryImpl');

  @override
  Future<Result<SaludServidorModel>> consultar() async {
    final resultado = await _apiClient.consultarSalud();
    switch (resultado) {
      case Error<SaludApiModel>():
        _log.warning('El servidor no respondió al sondeo: ${resultado.error}');
        return Result.error(resultado.error);
      case Ok<SaludApiModel>():
    }

    final dto = resultado.value;
    final salud = SaludServidorModel(
      estado: EstadoSalud.desdeApi(dto.status),
      grupos: dto.groups,
    );
    _log.info('Salud del servidor: $salud');
    return Result.ok(salud);
  }
}
