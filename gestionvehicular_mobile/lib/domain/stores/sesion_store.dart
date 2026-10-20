import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../core/utils/result.dart';
import '../../inicio_sesion/data/repositories/autenticacion_repository.dart';
import '../models/sesion/usuario_model.dart';

/// Estado global de la sesión. Lo escucha el `redirect` del `GoRouter` y lo
/// leen las pantallas para conocer al usuario y su rol.
///
/// Es el único dueño del usuario en memoria: nadie más lo guarda.
class SesionStore extends ChangeNotifier {
  SesionStore({required AutenticacionRepository autenticacionRepository})
    : _autenticacionRepository = autenticacionRepository;

  final AutenticacionRepository _autenticacionRepository;
  final Logger _log = Logger('SesionStore');

  UsuarioModel? _usuario;
  bool _cargando = true;
  bool _sesionExpirada = false;

  /// Usuario autenticado, o `null` si no hay sesión.
  UsuarioModel? get usuario => _usuario;

  /// `true` mientras se restaura la sesión al abrir la app. El router muestra
  /// la pantalla de carga y no redirige mientras esto sea `true`.
  bool get cargando => _cargando;

  /// `true` cuando la capa de red no pudo renovar el jwt.
  bool get sesionExpirada => _sesionExpirada;

  /// `true` si hay un usuario autenticado.
  bool get autenticado => _usuario != null;

  /// Registra al usuario recién autenticado. La llama el caso de uso del login.
  void establecerUsuario(UsuarioModel usuario) {
    _usuario = usuario;
    _sesionExpirada = false;
    _cargando = false;
    _log.info('Sesión iniciada: ${usuario.correo} (${usuario.rol.valor})');
    notifyListeners();
  }

  /// Restaura la sesión al abrir la app: si hay un token guardado se pide
  /// `GET /usuarios/detalle`; si falla, se vuelve al login.
  Future<void> restaurar() async {
    _cargando = true;
    notifyListeners();

    if (!await _autenticacionRepository.haySesionGuardada()) {
      _usuario = null;
      _cargando = false;
      notifyListeners();
      return;
    }

    final resultado = await _autenticacionRepository.obtenerUsuarioActual();
    switch (resultado) {
      case Ok<UsuarioModel>():
        _usuario = resultado.value;
        _sesionExpirada = false;
        _log.info('Sesión restaurada: ${resultado.value.correo}');
      case Error<UsuarioModel>():
        _log.warning('No se pudo restaurar la sesión: ${resultado.error}');
        await _autenticacionRepository.limpiarTokens();
        _usuario = null;
    }
    _cargando = false;
    notifyListeners();
  }

  /// Cierra la sesión llamando a la api; la limpieza local ocurre igual.
  Future<Result<void>> cerrarSesion() async {
    final resultado = await _autenticacionRepository.cerrarSesion();
    _usuario = null;
    _sesionExpirada = false;
    _cargando = false;
    notifyListeners();
    return resultado;
  }

  /// La usa la capa de red cuando el jwt ya no sirve y no se pudo renovar.
  void expirarSesion() {
    if (_usuario == null && !_sesionExpirada) return;
    _log.warning('Sesión expirada');
    _usuario = null;
    _sesionExpirada = true;
    _cargando = false;
    notifyListeners();
  }

  /// Limpia el aviso de sesión expirada una vez mostrado en el login.
  void consumirSesionExpirada() {
    if (!_sesionExpirada) return;
    _sesionExpirada = false;
    notifyListeners();
  }
}
