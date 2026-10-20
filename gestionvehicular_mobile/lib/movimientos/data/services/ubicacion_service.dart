import '../../../core/utils/result.dart';
import '../../domain/models/ubicacion_model.dart';

/// Por qué no se pudo obtener la ubicación. La ui decide qué decirle al
/// guardia según el caso, y en todos ellos el movimiento se puede registrar
/// igual: `latitud` y `longitud` son opcionales en la api.
enum MotivoSinUbicacion {
  /// El guardia negó el permiso esta vez; se le puede volver a pedir.
  permisoNegado,

  /// El guardia negó el permiso para siempre; hay que ir a los ajustes.
  permisoNegadoParaSiempre,

  /// El gps o los servicios de ubicación del teléfono están apagados.
  servicioApagado,

  /// El teléfono no devolvió la posición (tiempo agotado o error del sistema).
  errorDelDispositivo,
}

/// Resultado de pedir el permiso de ubicación.
enum EstadoPermisoUbicacion {
  /// Concedido: los movimientos se registran con coordenadas.
  concedido,

  /// Negado esta vez; se puede volver a pedir.
  negado,

  /// Negado para siempre; solo se arregla desde los ajustes del teléfono.
  negadoParaSiempre,

  /// Los servicios de ubicación del teléfono están apagados.
  servicioApagado;

  /// `true` cuando se puede intentar obtener coordenadas.
  bool get permiteUbicar => this == EstadoPermisoUbicacion.concedido;
}

/// Error que devuelve [UbicacionService] cuando no hay coordenadas. Lleva el
/// [motivo] para que la ui no tenga que interpretar un texto.
final class UbicacionException implements Exception {
  const UbicacionException(this.motivo, this.mensaje);

  final MotivoSinUbicacion motivo;
  final String mensaje;

  @override
  String toString() => 'UbicacionException($motivo, $mensaje)';
}

/// Acceso a la ubicación del dispositivo. La ui y los casos de uso dependen de
/// esta interfaz, nunca de `geolocator`.
abstract class UbicacionService {
  /// Pide el permiso de ubicación (o devuelve el estado actual si ya se
  /// resolvió antes). Se llama al abrir la pantalla de movimientos.
  Future<EstadoPermisoUbicacion> solicitarPermiso();

  /// Estado del permiso sin pedirlo de nuevo.
  Future<EstadoPermisoUbicacion> consultarPermiso();

  /// Coordenadas actuales. Devuelve `Result.error` con [UbicacionException]
  /// cuando no se pueden obtener.
  Future<Result<UbicacionModel>> obtenerUbicacion();

  /// Abre los ajustes de la app para que el guardia conceda el permiso que
  /// negó para siempre.
  Future<void> abrirAjustes();
}
