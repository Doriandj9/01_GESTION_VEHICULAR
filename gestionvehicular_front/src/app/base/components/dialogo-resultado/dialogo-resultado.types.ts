/**
 * Contrato del diálogo global de resultado. Se describe con `Type` porque son
 * objetos y atributos, no contratos de clases.
 */

/** Tipo de resultado que muestra el diálogo */
export type TipoResultado = 'exito' | 'error';

/** Contenido que se muestra en el diálogo */
export type ResultadoDialogo = {
    /** Determina el icono animado y el color del diálogo */
    tipo: TipoResultado;
    /** Título corto; si no se envía se usa uno por defecto según el tipo */
    titulo?: string;
    /** Mensaje principal: en los errores es el `message` de la api y siempre se muestra */
    mensaje: string;
    /**
     * Validaciones por campo del error de la api (`errors`). Si trae elementos
     * se muestran como lista debajo del mensaje principal.
     */
    errores?: Record<string, string>;
};
