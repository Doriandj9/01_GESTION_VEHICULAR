import '../../../core/utils/result.dart';
import '../../domain/models/salud_servidor_model.dart';

/// Contrato del sondeo de salud del backend. La ui y el store dependen de esta
/// interfaz, nunca del `ApiClient`.
abstract class SaludRepository {
  /// `GET /actuator/health`. Devuelve `Ok` con el estado reportado —incluido
  /// `DOWN`— y `Error` solo cuando no hubo respuesta legible (servidor apagado,
  /// sin red, url equivocada o cuerpo inesperado).
  Future<Result<SaludServidorModel>> consultar();
}
