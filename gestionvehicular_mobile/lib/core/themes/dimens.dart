import 'package:flutter/material.dart';

/// Medidas de la ui. Nunca se escriben paddings ni tamaños a mano en los
/// widgets: siempre se piden a `Dimens.of(context)` o a las constantes.
abstract final class Dimens {
  const Dimens();

  /// Separación horizontal general entre elementos.
  static const paddingHorizontal = 16.0;

  /// Separación vertical general entre elementos.
  static const paddingVertical = 16.0;

  /// Escala de espacios, de menor a mayor.
  static const espacioMinimo = 4.0;
  static const espacioPequeno = 8.0;
  static const espacioMedio = 16.0;
  static const espacioGrande = 24.0;
  static const espacioExtra = 32.0;

  /// Radios de esquina (tarjetas y campos del mockup).
  static const radioTarjeta = 12.0;
  static const radioCampo = 10.0;
  static const radioBoton = 10.0;

  /// Grosor del borde de tarjetas y campos.
  static const grosorBorde = 1.0;

  /// Barra verde de acento que encabeza cada tarjeta del mockup.
  static const anchoAcento = 28.0;
  static const altoAcento = 3.0;

  /// Alto de los botones y campos de texto.
  static const altoBoton = 48.0;
  static const altoCampo = 52.0;

  /// Diámetro del botón circular de la huella en el login.
  static const tamanoBotonHuella = 64.0;

  /// Tamaño del recuadro del escáner de QR.
  static const tamanoVisorQr = 260.0;

  /// Padding horizontal de los bordes de la pantalla.
  double get paddingScreenHorizontal;

  /// Padding vertical de los bordes de la pantalla.
  double get paddingScreenVertical;

  /// Ancho máximo del contenido (evita líneas larguísimas en tablets).
  double get anchoMaximoContenido;

  /// Tamaño del logotipo de la entidad en el login.
  double get tamanoLogo;

  EdgeInsets get edgeInsetsScreenHorizontal =>
      EdgeInsets.symmetric(horizontal: paddingScreenHorizontal);

  EdgeInsets get edgeInsetsScreenSymmetric => EdgeInsets.symmetric(
    horizontal: paddingScreenHorizontal,
    vertical: paddingScreenVertical,
  );

  /// Padding interno de una tarjeta.
  EdgeInsets get edgeInsetsTarjeta => const EdgeInsets.all(espacioMedio);

  static const Dimens mobile = _DimensMobile();
  static const Dimens tablet = _DimensTablet();

  /// Devuelve las medidas según el ancho de la pantalla.
  factory Dimens.of(BuildContext context) =>
      switch (MediaQuery.sizeOf(context).width) {
        >= 600 => tablet,
        _ => mobile,
      };
}

/// Medidas para teléfono (caso principal de la app).
final class _DimensMobile extends Dimens {
  const _DimensMobile();

  @override
  final double paddingScreenHorizontal = Dimens.paddingHorizontal;

  @override
  final double paddingScreenVertical = Dimens.paddingVertical;

  @override
  final double anchoMaximoContenido = double.infinity;

  @override
  final double tamanoLogo = 96.0;
}

/// Medidas para tablet.
final class _DimensTablet extends Dimens {
  const _DimensTablet();

  @override
  final double paddingScreenHorizontal = 32.0;

  @override
  final double paddingScreenVertical = 24.0;

  @override
  final double anchoMaximoContenido = 520.0;

  @override
  final double tamanoLogo = 128.0;
}
