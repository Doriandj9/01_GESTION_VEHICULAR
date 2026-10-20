/**
 * Métricas mínimas que debe cumplir una clave nueva. Se evalúan en el dominio
 * para que la ui solo las muestre.
 */

/** Longitud mínima exigida */
export const LONGITUD_MINIMA_CLAVE = 8;

/** Una regla de la clave y si la clave evaluada la cumple */
export type ReglaClave = {
    /** Texto que se muestra al usuario */
    texto: string;
    /** Resultado de la evaluación */
    cumple: boolean;
};

/** Evalúa las métricas básicas de una clave nueva */
export function evaluarClave(clave: string): ReglaClave[] {
    return [
        { texto: `Al menos ${LONGITUD_MINIMA_CLAVE} caracteres`, cumple: clave.length >= LONGITUD_MINIMA_CLAVE },
        { texto: 'Una letra mayúscula', cumple: /[A-ZÁÉÍÓÚÑ]/.test(clave) },
        { texto: 'Una letra minúscula', cumple: /[a-záéíóúñ]/.test(clave) },
        { texto: 'Un número', cumple: /[0-9]/.test(clave) },
        { texto: 'Un carácter especial', cumple: /[^A-Za-zÁÉÍÓÚÑáéíóúñ0-9]/.test(clave) },
        { texto: 'Sin espacios', cumple: clave.length > 0 && !/\s/.test(clave) }
    ];
}

/** Indica si la clave cumple todas las métricas */
export function claveEsValida(clave: string): boolean {
    return evaluarClave(clave).every(regla => regla.cumple);
}

/** Nivel de fortaleza de la clave, de 0 a 3, para el indicador visual */
export function fortalezaClave(clave: string): number {
    const cumplidas = evaluarClave(clave).filter(regla => regla.cumple).length;

    if (cumplidas <= 2) { return 0; }
    if (cumplidas <= 4) { return 1; }
    if (cumplidas === 5) { return 2; }
    return 3;
}
