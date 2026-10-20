import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../acceso_biometrico/data/repositories/acceso_biometrico_repository.dart';
import '../acceso_biometrico/data/repositories/acceso_biometrico_repository_impl.dart';
import '../acceso_biometrico/data/services/biometria_service.dart';
import '../acceso_biometrico/data/services/biometria_service_impl.dart';
import '../acceso_biometrico/data/sources/base_datos_local.dart';
import '../acceso_biometrico/data/sources/credencial_biometrica_dao.dart';
import '../acceso_biometrico/domain/use_cases/iniciar_sesion_biometrica_use_case.dart';
import '../cambiar_clave/domain/use_cases/cambiar_clave_use_case.dart';
import '../data/services/api/api_client.dart';
import '../data/stores/token_store.dart';
import '../domain/stores/sesion_store.dart';
import '../inicio_sesion/data/repositories/autenticacion_repository.dart';
import '../inicio_sesion/data/repositories/autenticacion_repository_impl.dart';
import '../inicio_sesion/domain/use_cases/cerrar_sesion_use_case.dart';
import '../inicio_sesion/domain/use_cases/iniciar_sesion_use_case.dart';
import '../movimientos/data/repositories/movimiento_repository.dart';
import '../movimientos/data/repositories/movimiento_repository_impl.dart';
import '../movimientos/data/services/ubicacion_service.dart';
import '../movimientos/data/services/ubicacion_service_impl.dart';
import '../movimientos/domain/use_cases/listar_mis_movimientos_use_case.dart';
import '../movimientos/domain/use_cases/registrar_movimiento_use_case.dart';
import '../salud_servidor/data/repositories/salud_repository.dart';
import '../salud_servidor/data/repositories/salud_repository_impl.dart';
import '../salud_servidor/domain/stores/salud_store.dart';
import 'env.dart';

/// Providers de la app, en orden de dependencia: almacenes -> cliente de api
/// -> repositorios -> stores globales -> casos de uso.
///
/// Los viewmodels **no** se registran aquí: se crean en el `builder` de su
/// ruta para que mueran con la pantalla.
List<SingleChildWidget> get appProviders {
  return [
    // Almacenamiento seguro de los tokens (único acceso al jwt).
    Provider(create: (context) => TokenStore()),

    // Cliente http único. La url base sale de `Env`, nunca escrita a mano.
    Provider(
      create: (context) =>
          ApiClient(uri: Uri.parse(Env.apiUrl), tokenStore: context.read()),
    ),

    // Base de datos sqlite local y dao de la credencial biométrica.
    Provider(create: (context) => BaseDatosLocal()),
    Provider(
      create: (context) => CredencialBiometricaDao(baseDatos: context.read()),
    ),

    // Biometría del dispositivo (local_auth), casteada a su interfaz.
    Provider(create: (context) => BiometriaServiceImpl() as BiometriaService),

    // Repositorios, casteados a su interfaz.
    Provider(
      create: (context) => AutenticacionRepositoryImpl(
        apiClient: context.read(),
        tokenStore: context.read(),
      ) as AutenticacionRepository,
    ),
    Provider(
      create: (context) => AccesoBiometricoRepositoryImpl(
        credencialDao: context.read(),
        tokenStore: context.read(),
        biometriaService: context.read(),
      ) as AccesoBiometricoRepository,
    ),

    Provider(
      create: (context) =>
          SaludRepositoryImpl(apiClient: context.read()) as SaludRepository,
    ),

    // Estado global de la sesión. No se restaura aquí: la restauración la
    // dispara el `SaludStore` cuando confirma que el servidor está arriba.
    ChangeNotifierProvider(
      lazy: false,
      create: (context) {
        final sesionStore = SesionStore(
          autenticacionRepository: context.read(),
        );
        final accesoBiometrico = context.read<AccesoBiometricoRepository>();
        final apiClient = context.read<ApiClient>();
        // El cliente avisa al store cuando el jwt ya no se puede renovar.
        apiClient.alExpirarSesion = () {
          sesionStore.expirarSesion();
          // El refresh token guardado tampoco sirve ya: se olvida para no
          // ofrecer una huella que va a fallar.
          accesoBiometrico.olvidar();
        };
        // Cada refresco silencioso revoca el refresh token anterior, así que
        // la credencial guardada se actualiza con el nuevo.
        apiClient.alRenovarTokens = accesoBiometrico.recordar;
        return sesionStore;
      },
    ),

    // Salud del backend. `lazy: false` porque el sondeo de `/actuator/health`
    // es lo primero que hace la app: hasta que responde, el router se queda en
    // la pantalla de carga.
    ChangeNotifierProvider(
      lazy: false,
      create: (context) {
        final saludStore = SaludStore(saludRepository: context.read());
        // La sesión se restaura solo con el servidor arriba: si estuviera
        // caído, el fallo de `GET /usuarios/detalle` borraría los tokens
        // guardados por un problema que no es del guardia.
        saludStore.alEstarDisponible = context.read<SesionStore>().restaurar;
        saludStore.verificar();
        return saludStore;
      },
    ),

    // Casos de uso.
    Provider(
      create: (context) => IniciarSesionUseCase(
        autenticacionRepository: context.read(),
        accesoBiometricoRepository: context.read(),
        sesionStore: context.read(),
      ),
    ),
    Provider(
      create: (context) => IniciarSesionBiometricaUseCase(
        accesoBiometricoRepository: context.read(),
        autenticacionRepository: context.read(),
        sesionStore: context.read(),
      ),
    ),
    Provider(
      create: (context) => CerrarSesionUseCase(
        sesionStore: context.read(),
        accesoBiometricoRepository: context.read(),
      ),
    ),
    Provider(
      create: (context) => CambiarClaveUseCase(
        autenticacionRepository: context.read(),
        accesoBiometricoRepository: context.read(),
        sesionStore: context.read(),
      ),
    ),

    // Ubicación del dispositivo (geolocator), casteada a su interfaz.
    Provider(create: (context) => UbicacionServiceImpl() as UbicacionService),

    // Movimientos: repositorio y casos de uso.
    Provider(
      create: (context) =>
          MovimientoRepositoryImpl(apiClient: context.read())
              as MovimientoRepository,
    ),
    Provider(
      create: (context) => RegistrarMovimientoUseCase(
        movimientoRepository: context.read(),
        ubicacionService: context.read(),
      ),
    ),
    Provider(
      create: (context) => ListarMisMovimientosUseCase(
        movimientoRepository: context.read(),
        sesionStore: context.read(),
      ),
    ),
  ];
}
