import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

/// Base de datos sqlite local de la app. Hoy guarda una sola cosa: la
/// credencial del acceso biométrico.
///
/// Es el único archivo que abre la base: los dao piden la instancia aquí.
class BaseDatosLocal {
  BaseDatosLocal({Future<Database> Function()? abrir})
    : _abrir = abrir ?? _abrirPorDefecto;

  /// Nombre del archivo en el directorio de bases de datos de la app.
  static const archivo = 'gestionvehicular.db';

  /// Versión del esquema. Al subirla hay que atender `onUpgrade`.
  static const version = 1;

  /// Tabla de la credencial biométrica. Tiene como máximo una fila (`id = 1`):
  /// un dispositivo recuerda a un solo guardia.
  static const tablaCredencial = 'credencial_biometrica';

  final Future<Database> Function() _abrir;
  final Logger _log = Logger('BaseDatosLocal');

  Future<Database>? _instancia;

  /// Devuelve la base abierta, creándola la primera vez.
  Future<Database> get instancia => _instancia ??= _abrirYRegistrar();

  Future<Database> _abrirYRegistrar() async {
    final base = await _abrir();
    _log.info('Base de datos local lista (versión $version)');
    return base;
  }

  /// Cierra la base. Se usa en las pruebas; en la app vive mientras la app.
  Future<void> cerrar() async {
    final abierta = _instancia;
    _instancia = null;
    if (abierta != null) await (await abierta).close();
  }

  static Future<Database> _abrirPorDefecto() async {
    final ruta = '${await getDatabasesPath()}/$archivo';
    return openDatabase(
      ruta,
      version: version,
      onCreate: (base, _) => base.execute(sentenciaCrearCredencial),
    );
  }

  /// `refresh_token_b64` guarda el token en base64, como pide el proyecto.
  /// `expira_en` y `guardada_en` son epoch en milisegundos utc.
  static const sentenciaCrearCredencial =
      '''
      CREATE TABLE $tablaCredencial (
        id INTEGER PRIMARY KEY,
        correo TEXT NOT NULL,
        refresh_token_b64 TEXT NOT NULL,
        expira_en INTEGER NOT NULL,
        guardada_en INTEGER NOT NULL
      )
      ''';
}
