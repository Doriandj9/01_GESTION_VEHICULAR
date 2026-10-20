import { HttpErrorResponse } from '@angular/common/http';
import { ErrorRestGlobalResponse } from './apiTypes';

/** Mensaje usado cuando la api no devuelve un error con el formato esperado */
const MENSAJE_GENERICO = 'Ocurrió un error inesperado. Intente nuevamente.';

/** Error de la api ya listo para mostrarse en la ui */
export type ErrorApi = {
    /** Mensaje principal: siempre se muestra */
    message: string;
    /** Errores de validación por campo; vacío si no hay */
    errors: Record<string, string>;
};

/**
 * Traduce cualquier error de `HttpClient` al formato de la api. Toma el campo
 * `message` y, si `errors` trae validaciones, también las conserva.
 */
export function aErrorApi(error: unknown): ErrorApi {
    const cuerpo = cuerpoDelError(error);

    // Un `Error` que no viene de http es una validación que el propio front
    // levantó antes de llamar a la api (por ejemplo un rango de fechas al
    // revés): su mensaje ya está escrito para el usuario
    if (!cuerpo && error instanceof Error && !(error instanceof HttpErrorResponse) && error.message) {
        return { message: error.message, errors: {} };
    }

    return {
        message: cuerpo?.message || MENSAJE_GENERICO,
        errors: cuerpo?.errors && typeof cuerpo.errors === 'object' ? cuerpo.errors : {}
    };
}

/** Lista las validaciones por campo como pares [campo, mensaje] */
export function erroresDeValidacion(error: ErrorApi): [string, string][] {
    return Object.entries(error.errors);
}

/** Indica si el error trae validaciones de campos */
export function tieneValidaciones(error: ErrorApi): boolean {
    return Object.keys(error.errors).length > 0;
}

/** Extrae el cuerpo `ErrorRestGlobalResponse` de la respuesta http */
function cuerpoDelError(error: unknown): Partial<ErrorRestGlobalResponse> | null {
    if (!(error instanceof HttpErrorResponse)) {
        return null;
    }

    // El backend responde el error como json; si no, no hay nada que leer
    return typeof error.error === 'object' && error.error !== null ? error.error : null;
}
