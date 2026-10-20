import 'package:flutter/material.dart';

import 'colors.dart';
import 'dimens.dart';

/// Tema claro y oscuro de la app, armado a partir de `AppColors`.
/// Reproduce el estilo del mockup: barra superior carbón, tarjetas blancas
/// con borde fino y esquinas suaves, y el verde institucional como acento.
abstract final class AppTheme {
  static const _textTheme = TextTheme(
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );

  static ThemeData get lightTheme => _construir(AppColors.lightColorScheme);

  static ThemeData get darkTheme => _construir(AppColors.darkColorScheme);

  static ThemeData _construir(ColorScheme esquema) {
    final esClaro = esquema.brightness == Brightness.light;
    final fondo = esClaro ? AppColors.fondoClaro : AppColors.fondoOscuro;

    return ThemeData(
      useMaterial3: true,
      brightness: esquema.brightness,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondo,
      textTheme: _textTheme.apply(
        bodyColor: esquema.onSurface,
        displayColor: esquema.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: esClaro ? AppColors.carbon : AppColors.carbonOscuro,
        foregroundColor: AppColors.blanco,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.blanco,
        ),
      ),
      cardTheme: CardThemeData(
        color: esquema.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radioTarjeta),
          side: BorderSide(color: esquema.outline, width: Dimens.grosorBorde),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: esquema.outline,
        thickness: Dimens.grosorBorde,
        space: Dimens.espacioMedio,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Dimens.espacioMedio,
          vertical: Dimens.espacioPequeno + 4,
        ),
        hintStyle: TextStyle(
          color: esquema.onSurfaceVariant,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: esquema.onSurfaceVariant,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        border: _borde(esquema.outline),
        enabledBorder: _borde(esquema.outline),
        focusedBorder: _borde(esquema.primary, grosor: 2),
        errorBorder: _borde(esquema.error),
        focusedErrorBorder: _borde(esquema.error, grosor: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(Dimens.altoBoton),
          backgroundColor: esquema.primary,
          foregroundColor: esquema.onPrimary,
          textStyle: _textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radioBoton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(Dimens.altoBoton),
          foregroundColor: esquema.onSurface,
          side: BorderSide(color: esquema.outline, width: Dimens.grosorBorde),
          textStyle: _textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radioBoton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: esquema.primary,
          textStyle: _textTheme.labelLarge,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: esquema.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radioTarjeta),
        ),
        titleTextStyle: _textTheme.titleMedium?.copyWith(
          color: esquema.onSurface,
        ),
        contentTextStyle: _textTheme.bodyMedium?.copyWith(
          color: esquema.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: esClaro ? AppColors.carbon : AppColors.carbonClaro,
        contentTextStyle: _textTheme.bodyMedium?.copyWith(
          color: AppColors.blanco,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radioBoton),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: esquema.primary,
      ),
    );
  }

  static OutlineInputBorder _borde(Color color, {double grosor = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimens.radioCampo),
        borderSide: BorderSide(color: color, width: grosor),
      );
}
