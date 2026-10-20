import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';

import '../../../core/utils/result.dart';
import '../../domain/models/ubicacion_model.dart';
import 'ubicacion_service.dart';

/// Implementación de [UbicacionService] con `geolocator`. Es el único archivo
/// de la app que importa ese paquete.
class UbicacionServiceImpl extends UbicacionService {
  /// Precisión y tiempo máximo de espera: el guardia registra de pie junto al
  /// vehículo, así que no se espera indefinidamente por una lectura perfecta.
  static const _ajustes = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 10),
  );

  final Logger _log = Logger('UbicacionServiceImpl');

  @override
  Future<EstadoPermisoUbicacion> solicitarPermiso() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _log.warning('Los servicios de ubicación están apagados');
      return EstadoPermisoUbicacion.servicioApagado;
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    return _aEstado(permiso);
  }

  @override
  Future<EstadoPermisoUbicacion> consultarPermiso() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return EstadoPermisoUbicacion.servicioApagado;
    }
    return _aEstado(await Geolocator.checkPermission());
  }

  @override
  Future<Result<UbicacionModel>> obtenerUbicacion() async {
    final estado = await consultarPermiso();
    if (!estado.permiteUbicar) {
      return Result.error(
        UbicacionException(_aMotivo(estado), _mensajePara(estado)),
      );
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: _ajustes,
      );
      _log.info(
        'Ubicación obtenida: ${posicion.latitude}, ${posicion.longitude}',
      );
      return Result.ok(
        UbicacionModel(
          latitud: posicion.latitude,
          longitud: posicion.longitude,
        ),
      );
    } on Exception catch (e) {
      // Tiempo agotado o fallo del sistema: no es motivo para cancelar el
      // registro, el movimiento se guarda sin coordenadas.
      _log.warning('No se pudo obtener la ubicación: $e');
      return Result.error(
        const UbicacionException(
          MotivoSinUbicacion.errorDelDispositivo,
          'No se pudo obtener la ubicación del dispositivo',
        ),
      );
    }
  }

  @override
  Future<void> abrirAjustes() async {
    await Geolocator.openAppSettings();
  }

  EstadoPermisoUbicacion _aEstado(LocationPermission permiso) =>
      switch (permiso) {
        LocationPermission.always ||
        LocationPermission.whileInUse => EstadoPermisoUbicacion.concedido,
        LocationPermission.deniedForever =>
          EstadoPermisoUbicacion.negadoParaSiempre,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => EstadoPermisoUbicacion.negado,
      };

  MotivoSinUbicacion _aMotivo(EstadoPermisoUbicacion estado) =>
      switch (estado) {
        EstadoPermisoUbicacion.negado => MotivoSinUbicacion.permisoNegado,
        EstadoPermisoUbicacion.negadoParaSiempre =>
          MotivoSinUbicacion.permisoNegadoParaSiempre,
        EstadoPermisoUbicacion.servicioApagado =>
          MotivoSinUbicacion.servicioApagado,
        EstadoPermisoUbicacion.concedido =>
          MotivoSinUbicacion.errorDelDispositivo,
      };

  String _mensajePara(EstadoPermisoUbicacion estado) => switch (estado) {
    EstadoPermisoUbicacion.negado => 'No se concedió el permiso de ubicación',
    EstadoPermisoUbicacion.negadoParaSiempre =>
      'El permiso de ubicación está negado en los ajustes del teléfono',
    EstadoPermisoUbicacion.servicioApagado =>
      'Los servicios de ubicación del teléfono están apagados',
    EstadoPermisoUbicacion.concedido =>
      'No se pudo obtener la ubicación del dispositivo',
  };
}
