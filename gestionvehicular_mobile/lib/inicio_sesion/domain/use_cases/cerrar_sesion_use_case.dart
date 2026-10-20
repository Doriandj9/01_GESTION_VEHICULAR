import 'package:logging/logging.dart';

import '../../../acceso_biometrico/data/repositories/acceso_biometrico_repository.dart';
import '../../../core/utils/result.dart';
import '../../../domain/stores/sesion_store.dart';

/// Caso de uso del cierre de sesión. Existe para que el olvido de la
/// credencial biométrica no quede suelto en la ui: cerrar sesión **también**
/// borra el acceso rápido.
///
/// Esto es a propósito. El teléfono de una garita puede tener registradas las
/// huellas de varios guardias: si al cerrar sesión quedara la credencial, el
/// guardia del turno siguiente podría reabrir la sesión del anterior con su
/// propia huella. Quien cierra sesión deja el dispositivo sin acceso rápido.
class CerrarSesionUseCase {
  CerrarSesionUseCase({
    required SesionStore sesionStore,
    required AccesoBiometricoRepository accesoBiometricoRepository,
  }) : _sesionStore = sesionStore,
       _accesoBiometricoRepository = accesoBiometricoRepository;

  final SesionStore _sesionStore;
  final AccesoBiometricoRepository _accesoBiometricoRepository;
  final Logger _log = Logger('CerrarSesionUseCase');

  Future<Result<void>> ejecutar() async {
    // Se olvida antes de cerrar: el cierre dispara la redirección al login y
    // ahí ya se consulta si hay credencial para ofrecer la huella.
    await _accesoBiometricoRepository.olvidar();
    _log.info('Acceso biométrico olvidado al cerrar sesión');
    return _sesionStore.cerrarSesion();
  }
}
