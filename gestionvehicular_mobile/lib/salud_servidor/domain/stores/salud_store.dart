import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../config/env.dart';
import '../../../core/utils/api_errors.dart';
import '../../../core/utils/result.dart';
import '../../../data/services/api/api_client.dart';
import '../../data/repositories/salud_repository.dart';
import '../models/salud_servidor_model.dart';

/// En qué punto está el sondeo del servidor.
enum SituacionServidor {
  /// Se está consultando `/actuator/health`.
  verificando,

  /// El actuator respondió `UP`: se puede usar la app.
  disponible,

  /// No respondió, respondió algo ilegible o respondió un estado distinto
  /// de `UP`.
  caido,
}

/// Estado global de la salud del backend. Es lo primero que se resuelve al
/// abrir la app: el `redirect` del router no deja pasar de la pantalla de
/// carga hasta que este store decide.
///
/// Se comprueba **antes** de restaurar la sesión a propósito. La restauración
/// borra los tokens si `GET /usuarios/detalle` falla, y un servidor apagado
/// haría exactamente eso: dejar al guardia sin sesión guardada por un problema
/// que no es suyo.
class SaludStore extends ChangeNotifier {
  SaludStore({required SaludRepository saludRepository})
    : _saludRepository = saludRepository;

  /// El servidor no contestó: apagado, sin red o url equivocada.
  static const mensajeNoSeEncuentra =
      'No se encuentra el servidor o no está levantado correctamente.';

  /// Contestó, pero reportando que algo suyo no funciona.
  static const mensajeConFallas =
      'El servidor está levantado pero no responde correctamente.';

  final SaludRepository _saludRepository;
  final Logger _log = Logger('SaludStore');

  SituacionServidor _situacion = SituacionServidor.verificando;
  SaludServidorModel? _salud;
  String _mensaje = '';
  List<String> _detalles = const [];

  /// Aviso de que el servidor quedó disponible. Lo asigna
  /// `dependencies.dart` para arrancar la restauración de la sesión.
  Future<void> Function()? alEstarDisponible;

  /// Punto en el que está el sondeo.
  SituacionServidor get situacion => _situacion;

  /// `true` mientras se consulta el actuator.
  bool get verificando => _situacion == SituacionServidor.verificando;

  /// `true` solo si el servidor respondió `UP`.
  bool get disponible => _situacion == SituacionServidor.disponible;

  /// Última salud leída, o `null` si no hubo respuesta legible.
  SaludServidorModel? get salud => _salud;

  /// Mensaje para el guardia cuando el servidor no se puede usar.
  String get mensaje => _mensaje;

  /// Detalles técnicos del problema: url sondeada, estado recibido y el error
  /// que devolvió la capa de red. Se muestran tal cual para que el soporte de
  /// la entidad sepa dónde mirar.
  List<String> get detalles => _detalles;

  /// Consulta `/actuator/health`. La llama el arranque de la app y el botón
  /// "Reintentar" de la pantalla de servidor no disponible.
  Future<void> verificar() async {
    _situacion = SituacionServidor.verificando;
    notifyListeners();

    final resultado = await _saludRepository.consultar();
    switch (resultado) {
      case Ok<SaludServidorModel>():
        _salud = resultado.value;
        if (resultado.value.estaArriba) {
          _situacion = SituacionServidor.disponible;
          _mensaje = '';
          _detalles = const [];
          _log.info('Servidor disponible');
          notifyListeners();
          // Con el servidor arriba ya tiene sentido restaurar la sesión.
          await alEstarDisponible?.call();
          return;
        }
        _situacion = SituacionServidor.caido;
        _mensaje = mensajeConFallas;
        _detalles = [
          'Url: $_urlSondeada',
          'Estado reportado: ${resultado.value.estado.valor} '
              '(${resultado.value.estado.etiqueta})',
          if (resultado.value.grupos.isNotEmpty)
            'Grupos: ${resultado.value.grupos.join(', ')}',
        ];
        _log.warning('Servidor con fallas: ${resultado.value}');

      case Error<SaludServidorModel>():
        final error = ApiErrors.normalizar(resultado.error);
        _salud = null;
        _situacion = SituacionServidor.caido;
        _mensaje = mensajeNoSeEncuentra;
        _detalles = [
          'Url: $_urlSondeada',
          'Detalle: ${error.message}',
          ...error.errors.entries.map((par) => '${par.key}: ${par.value}'),
        ];
        _log.severe('Servidor no disponible: ${error.message}');
    }
    notifyListeners();
  }

  /// Url exacta que se sondeó, para que el detalle del error sirva de algo.
  String get _urlSondeada => '${Env.apiBaseUrl}${ApiClient.rutaSalud}';
}
