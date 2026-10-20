import { Injectable, computed, signal } from '@angular/core';
import { ErrorApi } from '../../apiErrors';
import { ResultadoDialogo } from './dialogo-resultado.types';

/**
 * Servicio global del diálogo de resultado. Cualquier pantalla lo inyecta y
 * llama a `exito()` o `error()` después de una acción; el componente
 * `DialogoResultadoComponent`, montado una sola vez en la raíz, es el que
 * dibuja el resultado.
 */
@Injectable({ providedIn: 'root' })
export class DialogoResultadoService {
    /** Resultado visible; `null` cuando el diálogo está cerrado */
    private readonly _resultado = signal<ResultadoDialogo | null>(null);

    readonly resultado = this._resultado.asReadonly();

    /** Indica si el diálogo está abierto */
    readonly abierto = computed(() => this._resultado() !== null);

    /** Validaciones por campo del resultado, como pares [campo, mensaje] */
    readonly validaciones = computed<[string, string][]>(() => {
        const errores = this._resultado()?.errores;
        return errores ? Object.entries(errores) : [];
    });

    /** Muestra el diálogo de éxito */
    exito(mensaje: string, titulo?: string): void {
        this._resultado.set({ tipo: 'exito', titulo, mensaje });
    }

    /** Muestra el diálogo de error con el mensaje y las validaciones de la api */
    error(error: ErrorApi, titulo?: string): void {
        this._resultado.set({
            tipo: 'error',
            titulo,
            mensaje: error.message,
            errores: error.errors
        });
    }

    /** Muestra un resultado armado a mano */
    mostrar(resultado: ResultadoDialogo): void {
        this._resultado.set(resultado);
    }

    /** Cierra el diálogo */
    cerrar(): void {
        this._resultado.set(null);
    }
}
