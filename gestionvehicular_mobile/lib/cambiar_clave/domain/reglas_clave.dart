/// Métricas mínimas que debe cumplir una clave nueva. Se evalúan en el dominio
/// para que la ui solo las muestre.
///
/// Son las mismas reglas que aplica la web de administración
/// (`gestionvehicular_front`, `auth/domain/reglas-clave.ts`): si cambian allá,
/// cambian aquí.
library;

/// Longitud mínima exigida.
const int longitudMinimaClave = 8;

/// Una regla de la clave y si la clave evaluada la cumple.
final class ReglaClave {
  const ReglaClave({required this.texto, required this.cumple});

  /// Texto que se muestra al usuario.
  final String texto;

  /// Resultado de la evaluación.
  final bool cumple;

  @override
  String toString() => 'ReglaClave(texto: $texto, cumple: $cumple)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReglaClave &&
        other.texto == texto &&
        other.cumple == cumple;
  }

  @override
  int get hashCode => Object.hash(texto, cumple);
}

/// Evalúa las métricas básicas de una clave nueva.
List<ReglaClave> evaluarClave(String clave) {
  return [
    ReglaClave(
      texto: 'Al menos $longitudMinimaClave caracteres',
      cumple: clave.length >= longitudMinimaClave,
    ),
    ReglaClave(
      texto: 'Una letra mayúscula',
      cumple: RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(clave),
    ),
    ReglaClave(
      texto: 'Una letra minúscula',
      cumple: RegExp(r'[a-záéíóúñ]').hasMatch(clave),
    ),
    ReglaClave(texto: 'Un número', cumple: RegExp(r'[0-9]').hasMatch(clave)),
    ReglaClave(
      texto: 'Un carácter especial',
      cumple: RegExp(r'[^A-Za-zÁÉÍÓÚÑáéíóúñ0-9]').hasMatch(clave),
    ),
    ReglaClave(
      texto: 'Sin espacios',
      cumple: clave.isNotEmpty && !RegExp(r'\s').hasMatch(clave),
    ),
  ];
}

/// Indica si la clave cumple todas las métricas.
bool claveEsValida(String clave) =>
    evaluarClave(clave).every((regla) => regla.cumple);

/// Nivel de fortaleza de la clave, de 0 a 3, para el indicador visual.
int fortalezaClave(String clave) {
  final cumplidas = evaluarClave(clave).where((regla) => regla.cumple).length;

  if (cumplidas <= 2) return 0;
  if (cumplidas <= 4) return 1;
  if (cumplidas == 5) return 2;
  return 3;
}
