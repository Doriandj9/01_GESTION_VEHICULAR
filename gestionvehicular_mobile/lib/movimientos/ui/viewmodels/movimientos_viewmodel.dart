import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../core/utils/command.dart';
import '../../../core/utils/result.dart';
import '../../data/services/ubicacion_service.dart';
import '../../domain/models/movimiento_model.dart';
import '../../domain/models/movimiento_registrado_model.dart';
import '../../domain/models/tipo_movimiento.dart';
import '../../domain/use_cases/listar_mis_movimientos_use_case.dart';
import '../../domain/use_cases/registrar_movimiento_use_case.dart';

/// Viewmodel de la pantalla de registro de movimientos.
///
/// Al construirse pide el permiso de ubicación y carga los movimientos del día
/// de hoy. La cámara se pide al abrir el escáner, porque es `mobile_scanner`
/// quien dispara ese diálogo del sistema.
class MovimientosViewmodel extends ChangeNotifier {
  MovimientosViewmodel({
    required RegistrarMovimientoUseCase registrarMovimientoUseCase,
    required ListarMisMovimientosUseCase listarMisMovimientosUseCase,
    required UbicacionService ubicacionService,
  }) : _registrarMovimientoUseCase = registrarMovimientoUseCase,
       _listarMisMovimientosUseCase = listarMisMovimientosUseCase,
       _ubicacionService = ubicacionService {
    registrar = Command1<MovimientoModel, (String, TipoMovimiento)>(_registrar);
    cargarMovimientos = Command0<List<MovimientoRegistradoModel>>(
      _cargarMovimientos,
    )..execute();
    // Se pide el permiso de ubicación en cuanto se abre la pantalla, antes de
    // que el guardia escanee nada.
    pedirUbicacion = Command0<EstadoPermisoUbicacion>(_pedirUbicacion)
      ..execute();
  }

  final RegistrarMovimientoUseCase _registrarMovimientoUseCase;
  final ListarMisMovimientosUseCase _listarMisMovimientosUseCase;
  final UbicacionService _ubicacionService;
  final Logger _log = Logger('MovimientosViewmodel');

  /// Comando del registro: recibe (texto del QR, tipo de movimiento).
  late final Command1<MovimientoModel, (String, TipoMovimiento)> registrar;

  /// Comando que carga la lista de movimientos del filtro actual.
  late final Command0<List<MovimientoRegistradoModel>> cargarMovimientos;

  /// Comando que pide el permiso de ubicación. Se ejecuta al abrir la pantalla
  /// y se puede volver a ejecutar desde el aviso de la ui.
  late final Command0<EstadoPermisoUbicacion> pedirUbicacion;

  EstadoPermisoUbicacion? _estadoUbicacion;
  TipoMovimiento? _tipoEnCurso;
  List<MovimientoRegistradoModel> _movimientos = const [];

  /// Filtro de fecha. Por defecto, **hoy** desde las 00:00.
  DateTime _fechaFiltro = _hoy();

  /// Estado del permiso de ubicación, o `null` mientras no se ha resuelto.
  EstadoPermisoUbicacion? get estadoUbicacion => _estadoUbicacion;

  /// Tipo que se está registrando, para que la ui marque la tarjeta pulsada.
  TipoMovimiento? get tipoEnCurso => _tipoEnCurso;

  /// Movimientos del filtro actual, de más reciente a más antiguo.
  List<MovimientoRegistradoModel> get movimientos => _movimientos;

  /// Fecha desde la que se listan los movimientos.
  DateTime get fechaFiltro => _fechaFiltro;

  /// `true` si el filtro está en el día de hoy.
  bool get filtraHoy {
    final hoy = _hoy();
    return _fechaFiltro.year == hoy.year &&
        _fechaFiltro.month == hoy.month &&
        _fechaFiltro.day == hoy.day;
  }

  /// `true` si se registrará sin coordenadas (permiso negado o gps apagado).
  bool get registraraSinUbicacion =>
      _estadoUbicacion != null && !_estadoUbicacion!.permiteUbicar;

  /// Abre los ajustes del teléfono para conceder el permiso negado.
  Future<void> abrirAjustes() => _ubicacionService.abrirAjustes();

  /// Cambia el filtro y recarga la lista. La hora se fija a las 00:00 porque
  /// la api interpreta `fecha` como un "desde" inclusive.
  Future<void> cambiarFecha(DateTime fecha) async {
    _fechaFiltro = DateTime(fecha.year, fecha.month, fecha.day);
    notifyListeners();
    await cargarMovimientos.execute();
  }

  /// Vuelve el filtro al día de hoy.
  Future<void> volverAHoy() => cambiarFecha(_hoy());

  static DateTime _hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  Future<Result<EstadoPermisoUbicacion>> _pedirUbicacion() async {
    final estado = await _ubicacionService.solicitarPermiso();
    _estadoUbicacion = estado;
    _log.info('Permiso de ubicación: ${estado.name}');
    notifyListeners();
    return Result.ok(estado);
  }

  Future<Result<List<MovimientoRegistradoModel>>> _cargarMovimientos() async {
    final resultado = await _listarMisMovimientosUseCase.ejecutar(
      desde: _fechaFiltro,
    );
    switch (resultado) {
      case Ok<List<MovimientoRegistradoModel>>():
        _movimientos = resultado.value;
        _log.info('${_movimientos.length} movimientos en la lista');
      case Error<List<MovimientoRegistradoModel>>():
        _movimientos = const [];
        _log.warning('No se pudo listar: ${resultado.error}');
    }
    notifyListeners();
    return resultado;
  }

  Future<Result<MovimientoModel>> _registrar(
    (String, TipoMovimiento) datos,
  ) async {
    final (data, tipo) = datos;
    _tipoEnCurso = tipo;
    notifyListeners();

    final resultado = await _registrarMovimientoUseCase.ejecutar(
      data: data,
      tipo: tipo,
    );

    _tipoEnCurso = null;
    switch (resultado) {
      case Ok<MovimientoModel>():
        _log.info('Movimiento registrado: ${resultado.value}');
        // La lista es la confirmación de que el registro quedó guardado: si el
        // movimiento es de hoy y el filtro está en otro día, se vuelve a hoy.
        notifyListeners();
        if (filtraHoy) {
          await cargarMovimientos.execute();
        } else {
          await volverAHoy();
        }
        return resultado;
      case Error<MovimientoModel>():
        _log.warning('Error al registrar: ${resultado.error}');
    }
    notifyListeners();
    return resultado;
  }
}
