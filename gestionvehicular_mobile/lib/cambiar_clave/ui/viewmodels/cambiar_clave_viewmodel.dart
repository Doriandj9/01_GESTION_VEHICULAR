import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../core/utils/command.dart';
import '../../../core/utils/result.dart';
import '../../../domain/models/sesion/usuario_model.dart';
import '../../domain/reglas_clave.dart';
import '../../domain/use_cases/cambiar_clave_use_case.dart';

/// Viewmodel de la pantalla de cambio obligatorio de clave.
///
/// Mantiene el texto de los tres campos porque de ellos dependen el listado de
/// reglas, el indicador de fortaleza y si el botón se habilita: son estado de
/// la vista, no de los `TextEditingController`.
class CambiarClaveViewmodel extends ChangeNotifier {
  CambiarClaveViewmodel({required CambiarClaveUseCase cambiarClaveUseCase})
    : _cambiarClaveUseCase = cambiarClaveUseCase {
    cambiarClave = Command1<UsuarioModel, (String, String)>(_cambiarClave);
  }

  final CambiarClaveUseCase _cambiarClaveUseCase;
  final Logger _log = Logger('CambiarClaveViewmodel');

  /// Comando del cambio: recibe (clave actual, clave nueva).
  late final Command1<UsuarioModel, (String, String)> cambiarClave;

  String _claveActual = '';
  String _claveNueva = '';
  String _claveRepetida = '';
  bool _clavesVisibles = false;

  String get claveActual => _claveActual;
  String get claveNueva => _claveNueva;
  String get claveRepetida => _claveRepetida;

  /// `true` cuando las claves se muestran en claro.
  bool get clavesVisibles => _clavesVisibles;

  /// Métricas de la clave nueva, para el listado de la vista.
  List<ReglaClave> get reglas => evaluarClave(_claveNueva);

  /// Nivel de fortaleza de 0 a 3.
  int get fortaleza => fortalezaClave(_claveNueva);

  /// `true` si las dos claves nuevas coinciden.
  bool get clavesCoinciden =>
      _claveRepetida.isNotEmpty && _claveNueva == _claveRepetida;

  /// La clave nueva no puede ser igual a la actual.
  bool get claveEsDistinta =>
      _claveNueva.isNotEmpty && _claveNueva != _claveActual;

  /// Habilita el envío solo cuando todo está correcto.
  bool get puedeEnviar =>
      _claveActual.isNotEmpty &&
      claveEsValida(_claveNueva) &&
      clavesCoinciden &&
      claveEsDistinta &&
      !cambiarClave.running;

  void actualizarClaveActual(String valor) {
    _claveActual = valor;
    notifyListeners();
  }

  void actualizarClaveNueva(String valor) {
    _claveNueva = valor;
    notifyListeners();
  }

  void actualizarClaveRepetida(String valor) {
    _claveRepetida = valor;
    notifyListeners();
  }

  void alternarVisibilidadClaves() {
    _clavesVisibles = !_clavesVisibles;
    notifyListeners();
  }

  /// Vacía los tres campos. La vista la llama tras un error, igual que la web.
  void limpiarCampos() {
    _claveActual = '';
    _claveNueva = '';
    _claveRepetida = '';
    notifyListeners();
  }

  Future<Result<UsuarioModel>> _cambiarClave((String, String) claves) async {
    final (actual, nueva) = claves;
    final resultado = await _cambiarClaveUseCase.ejecutar(
      claveActual: actual,
      claveNueva: nueva,
    );
    if (resultado is Error<UsuarioModel>) {
      _log.warning('Error al cambiar la clave: ${resultado.error}');
    }
    return resultado;
  }
}
