# Gestión Vehicular (app móvil)

Stack: Flutter (Dart) + provider + go_router. Una sola app móvil para el rol `GUARDIA`:
login y registro de movimientos (`ENTRADA` / `SALIDA`) escaneando el QR del vehículo.

# Convenciones
- Código y comentarios deben ir en español. Clases e interfaces (`abstract`) en `PascalCase`;
  propiedades, variables y métodos en `camelCase`; archivos en `snake_case`.
- Arquitectura por capas en `lib/` (`data`, `domain` opcional, `ui` con MVVM). Para crear una
  funcionalidad nueva usa la skill `create-functionality` (`.claude/skills/create-functionality/`).
- Las decisiones tomadas y el contrato de la api están en `MEMORY.md`. Léelo antes de empezar y no
  vuelvas a discutir lo que ya está ahí.

# Comandos
- Instalar dependencias: `flutter pub get`
- Generar código del `.env`: `dart run build_runner build --delete-conflicting-outputs`
- Formatear: `dart format lib`
- Analizar: `flutter analyze`
- Pruebas: `flutter test`
- Ejecutar: `flutter run`