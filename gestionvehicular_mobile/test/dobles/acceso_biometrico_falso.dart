import 'package:gestionvehicular_mobile/acceso_biometrico/data/repositories/acceso_biometrico_repository.dart';
import 'package:gestionvehicular_mobile/acceso_biometrico/data/services/biometria_service.dart';
import 'package:gestionvehicular_mobile/acceso_biometrico/domain/models/credencial_biometrica_model.dart';

/// Doble del acceso biométrico, escrito a mano en lugar de con `mocktail`
/// porque todas sus operaciones devuelven `Future` y un mock sin stub
/// devolvería `null`.
///
/// Registra lo que se le pidió para poder afirmarlo en las pruebas.
class AccesoBiometricoFalso extends AccesoBiometricoRepository {
  AccesoBiometricoFalso({
    this.estado = EstadoBiometria.disponible,
    this.identidad = ResultadoBiometria.autorizado,
    this.credencial,
  });

  EstadoBiometria estado;
  ResultadoBiometria identidad;
  CredencialBiometricaModel? credencial;

  int vecesRecordada = 0;
  int vecesOlvidada = 0;
  int vecesComprobada = 0;

  @override
  Future<void> recordar() async => vecesRecordada++;

  @override
  Future<void> olvidar() async {
    vecesOlvidada++;
    credencial = null;
  }

  @override
  Future<CredencialBiometricaModel?> credencialVigente() async => credencial;

  @override
  Future<EstadoBiometria> estadoBiometria() async => estado;

  @override
  Future<ResultadoBiometria> comprobarIdentidad() async {
    vecesComprobada++;
    return identidad;
  }
}

/// Credencial de prueba, vigente por [vigencia] (por defecto, una semana como
/// el refresh token del backend).
CredencialBiometricaModel credencialDePrueba({
  String correo = 'guardia@gadmjs.gob.ec',
  String refreshToken = 'RT-GUARDADO',
  Duration vigencia = const Duration(days: 7),
}) {
  return CredencialBiometricaModel(
    correo: correo,
    refreshToken: refreshToken,
    expiraEn: DateTime.now().toUtc().add(vigencia),
    guardadaEn: DateTime.now().toUtc(),
  );
}
