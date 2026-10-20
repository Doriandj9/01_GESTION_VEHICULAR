import 'package:logging/logging.dart';

import '../../../data/stores/token_store.dart';
import '../../domain/models/credencial_biometrica_model.dart';
import '../services/biometria_service.dart';
import '../sources/credencial_biometrica_dao.dart';
import 'acceso_biometrico_repository.dart';

/// Implementación de [AccesoBiometricoRepository] sobre el dao de sqlite, el
/// `TokenStore` y el servicio de biometría.
class AccesoBiometricoRepositoryImpl extends AccesoBiometricoRepository {
  AccesoBiometricoRepositoryImpl({
    required CredencialBiometricaDao credencialDao,
    required TokenStore tokenStore,
    required BiometriaService biometriaService,
  }) : _credencialDao = credencialDao,
       _tokenStore = tokenStore,
       _biometriaService = biometriaService;

  /// Texto que muestra el sistema en el diálogo de la huella o el rostro.
  static const motivoBiometria = 'Confirme su identidad para ingresar';

  final CredencialBiometricaDao _credencialDao;
  final TokenStore _tokenStore;
  final BiometriaService _biometriaService;
  final Logger _log = Logger('AccesoBiometricoRepositoryImpl');

  @override
  Future<void> recordar() async {
    final estado = await _biometriaService.consultarEstado();
    if (!estado.permiteAutenticar) {
      _log.info('No se recuerda la sesión: biometría ${estado.name}');
      return;
    }

    final refreshToken = await _tokenStore.obtenerRefreshToken();
    if (refreshToken == null) {
      _log.warning('No hay refresh token que recordar');
      return;
    }

    final credencial = CredencialBiometricaModel.desdeRefreshToken(
      refreshToken,
    );
    if (credencial == null) {
      _log.warning('El refresh token no se pudo decodificar: no se recuerda');
      return;
    }
    await _credencialDao.guardar(credencial);
  }

  @override
  Future<CredencialBiometricaModel?> credencialVigente() async {
    final credencial = await _credencialDao.leer();
    if (credencial == null) return null;
    if (credencial.caducada) {
      // Pasada la caducidad del refresh token no hay nada que recuperar: se
      // borra para que el login no ofrezca un acceso que va a fallar.
      _log.info('La credencial caducó el ${credencial.expiraEn}: se borra');
      await _credencialDao.borrar();
      return null;
    }
    return credencial;
  }

  @override
  Future<void> olvidar() => _credencialDao.borrar();

  @override
  Future<EstadoBiometria> estadoBiometria() =>
      _biometriaService.consultarEstado();

  @override
  Future<ResultadoBiometria> comprobarIdentidad() =>
      _biometriaService.autenticar(motivo: motivoBiometria);
}
