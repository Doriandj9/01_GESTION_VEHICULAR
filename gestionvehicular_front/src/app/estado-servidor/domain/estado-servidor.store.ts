import { Injectable, computed, signal } from '@angular/core';
import { SaludServidor } from './models/salud-servidor.model';

/** Etapa de la verificación del servidor */
export type EtapaVerificacion = 'INICIAL' | 'VERIFICANDO' | 'ARRIBA' | 'CAIDO';

/**
 * Estado de salud del backend, resuelto al arrancar la aplicación. Lo lee el
 * componente global `EstadoServidorComponent`, que tapa la pantalla con el
 * motivo cuando el servidor no está disponible.
 */
@Injectable({ providedIn: 'root' })
export class EstadoServidorStore {
    private readonly _etapa = signal<EtapaVerificacion>('INICIAL');
    private readonly _salud = signal<SaludServidor | null>(null);
    private readonly _verificadoEn = signal<Date | null>(null);

    readonly etapa = this._etapa.asReadonly();
    readonly salud = this._salud.asReadonly();
    readonly verificadoEn = this._verificadoEn.asReadonly();

    /** El servidor respondió y se declara sano */
    readonly disponible = computed(() => this._etapa() === 'ARRIBA');

    /** El servidor respondió mal o no respondió: hay que avisarle al usuario */
    readonly caido = computed(() => this._etapa() === 'CAIDO');

    /** La verificación está en curso */
    readonly verificando = computed(() => this._etapa() === 'VERIFICANDO');

    /** Marca el inicio de la verificación */
    iniciarVerificacion(): void {
        this._etapa.set('VERIFICANDO');
    }

    /** Guarda el resultado de la verificación */
    establecer(salud: SaludServidor): void {
        this._salud.set(salud);
        this._etapa.set(salud.estaArriba() ? 'ARRIBA' : 'CAIDO');
        this._verificadoEn.set(new Date());
    }

    /** Vuelve al estado inicial */
    limpiar(): void {
        this._etapa.set('INICIAL');
        this._salud.set(null);
        this._verificadoEn.set(null);
    }
}
