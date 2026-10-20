import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/themes/dimens.dart';
import '../../domain/models/tipo_movimiento.dart';

/// Escáner del QR del vehículo. Se abre al pulsar una de las dos tarjetas y
/// devuelve el **texto del código** (un jwt que la api valida) con
/// `Navigator.pop`, o `null` si el guardia cancela.
///
/// El permiso de cámara lo pide `mobile_scanner` al arrancar la cámara; si se
/// niega, el paquete entrega un [MobileScannerException] con
/// `MobileScannerErrorCode.permissionDenied` y aquí se muestra el aviso.
class EscanerQrScreen extends StatefulWidget {
  const EscanerQrScreen({super.key, required this.tipo});

  /// Tipo que se va a registrar, solo para rotular la pantalla.
  final TipoMovimiento tipo;

  /// Abre el escáner y espera el texto leído.
  static Future<String?> abrir(BuildContext context, TipoMovimiento tipo) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => EscanerQrScreen(tipo: tipo)),
    );
  }

  @override
  State<EscanerQrScreen> createState() => _EscanerQrScreenState();
}

class _EscanerQrScreenState extends State<EscanerQrScreen> {
  final Logger _log = Logger('EscanerQrScreen');

  /// Solo códigos QR y sin repetir lecturas del mismo código.
  final _controlador = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Evita que dos lecturas seguidas cierren la pantalla dos veces.
  bool _yaLeido = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture captura) {
    if (_yaLeido) return;

    final texto = captura.barcodes
        .map((codigo) => codigo.rawValue)
        .firstWhere(
          (valor) => valor != null && valor.trim().isNotEmpty,
          orElse: () => null,
        );
    if (texto == null) return;

    _yaLeido = true;
    _log.info('QR leído para ${widget.tipo.valor}');
    Navigator.of(context).pop(texto);
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Escanear ${widget.tipo.etiqueta.toLowerCase()}'),
        actions: [
          // La linterna ayuda en los turnos de noche.
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controlador,
            builder: (context, estado, _) {
              final encendida = estado.torchState == TorchState.on;

              return IconButton(
                tooltip: encendida ? 'Apagar linterna' : 'Encender linterna',
                icon: Icon(
                  encendida ? Icons.flashlight_on : Icons.flashlight_off,
                ),
                onPressed: () => _controlador.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controlador,
        onDetect: _onDetect,
        errorBuilder: (context, error) =>
            _AvisoDeCamara(error: error, esquema: esquema, textos: textos),
        overlayBuilder: (context, constraints) => const _MarcoDeEscaneo(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.espacioMedio),
          child: Text(
            'Apunte la cámara al código QR del vehículo',
            textAlign: TextAlign.center,
            style: textos.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

/// Recuadro que indica dónde encuadrar el código.
class _MarcoDeEscaneo extends StatelessWidget {
  const _MarcoDeEscaneo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: Dimens.tamanoVisorQr,
        height: Dimens.tamanoVisorQr,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(Dimens.radioTarjeta),
        ),
      ),
    );
  }
}

/// Aviso cuando la cámara no está disponible, con el caso del permiso negado
/// tratado aparte porque es el único que el guardia puede resolver.
class _AvisoDeCamara extends StatelessWidget {
  const _AvisoDeCamara({
    required this.error,
    required this.esquema,
    required this.textos,
  });

  final MobileScannerException error;
  final ColorScheme esquema;
  final TextTheme textos;

  @override
  Widget build(BuildContext context) {
    final esPermiso =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    final mensaje = esPermiso
        ? 'Sin permiso de cámara no se puede leer el código QR del vehículo. '
              'Concédalo en los ajustes del teléfono.'
        : 'No se pudo abrir la cámara. Intente nuevamente.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.espacioGrande),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esPermiso
                  ? Icons.no_photography_outlined
                  : Icons.videocam_off_outlined,
              color: esquema.error,
              size: Dimens.espacioExtra,
            ),
            const SizedBox(height: Dimens.espacioMedio),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: Dimens.espacioGrande),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
