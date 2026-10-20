import 'package:flutter/material.dart';

/// Colores institucionales del GADMJS tomados del mockup
/// (`assets/img/mockup.png`): barra superior carbón, acentos verdes y
/// tarjetas blancas sobre un fondo gris muy claro.
abstract final class AppColors {
  // Verde institucional
  static const primario = Color(0xFF1A9A3E);
  static const primarioClaro = Color(0xFF4CC46B);
  static const primarioOscuro = Color(0xFF0F7A2E);

  /// Verde muy suave para fondos de realce (chips, avisos de éxito).
  static const primarioSuave = Color(0xFFE6F5EA);

  // Negro carbón (barra superior del mockup), no negro puro
  static const carbon = Color(0xFF2B2B2B);
  static const carbonClaro = Color(0xFF3D3D3D);
  static const carbonOscuro = Color(0xFF1A1A1A);

  // Neutros
  static const blanco = Color(0xFFFFFFFF);
  static const fondoClaro = Color(0xFFF7F8F7);
  static const borde = Color(0xFFE4E7E4);
  static const textoSecundario = Color(0xFF8A8F8A);

  // Superficies del tema oscuro
  static const fondoOscuro = Color(0xFF121212);
  static const superficieOscura = Color(0xFF1E1E1E);
  static const bordeOscuro = Color(0xFF3A3A3A);
  static const textoSecundarioOscuro = Color(0xFFAEB3AE);

  // Estados
  static const error = Color(0xFFB00020);
  static const errorClaro = Color(0xFFFCE8EA);
  static const exito = primario;
  static const advertencia = Color(0xFFE2A200);

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primario,
    onPrimary: blanco,
    primaryContainer: primarioSuave,
    onPrimaryContainer: primarioOscuro,
    secondary: carbon,
    onSecondary: blanco,
    secondaryContainer: carbonClaro,
    onSecondaryContainer: blanco,
    surface: blanco,
    onSurface: carbon,
    surfaceContainerLowest: blanco,
    surfaceContainerLow: fondoClaro,
    surfaceContainer: fondoClaro,
    onSurfaceVariant: textoSecundario,
    outline: borde,
    outlineVariant: borde,
    error: error,
    onError: blanco,
    errorContainer: errorClaro,
    onErrorContainer: error,
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primarioClaro,
    onPrimary: carbonOscuro,
    primaryContainer: primarioOscuro,
    onPrimaryContainer: blanco,
    secondary: blanco,
    onSecondary: carbonOscuro,
    secondaryContainer: carbonClaro,
    onSecondaryContainer: blanco,
    surface: superficieOscura,
    onSurface: blanco,
    surfaceContainerLowest: fondoOscuro,
    surfaceContainerLow: superficieOscura,
    surfaceContainer: superficieOscura,
    onSurfaceVariant: textoSecundarioOscuro,
    outline: bordeOscuro,
    outlineVariant: bordeOscuro,
    error: Color(0xFFCF6679),
    onError: carbonOscuro,
    errorContainer: Color(0xFF5C1B24),
    onErrorContainer: blanco,
  );
}
