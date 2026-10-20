import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { environment } from '../../../environments';
import { EstadoServidorStore } from '../domain/estado-servidor.store';
import { VerificarEstadoServidorUseCase } from '../domain/usecases/verificar-estado-servidor.usecase';

// -----------------------------------------------------------
// EstadoServidorComponent (Aviso global de servidor no disponible)
// -----------------------------------------------------------
/**
 * Se monta una sola vez en la raíz, junto al diálogo de resultado. Solo se
 * dibuja cuando la verificación del arranque dejó el estado en `CAIDO`: tapa la
 * pantalla con el motivo y ofrece reintentar, porque sin backend ninguna
 * pantalla de la aplicación sirve.
 */
@Component({
    selector: 'app-estado-servidor',
    standalone: true,
    imports: [CommonModule],
    templateUrl: './estado-servidor.component.html',
    styleUrls: ['./estado-servidor.component.css']
})
export class EstadoServidorComponent {
    private verificarEstadoServidorUseCase = inject(VerificarEstadoServidorUseCase);

    protected readonly store = inject(EstadoServidorStore);

    /** Identidad de la entidad y url consultada, para el pie del aviso */
    protected readonly entidad = environment.entidad;
    protected readonly urlSalud = environment.api.urlSalud;

    /** Indica que el usuario pidió reintentar y la consulta está en curso */
    readonly reintentando = signal(false);

    /** Vuelve a consultar el chequeo de salud */
    reintentar(): void {
        if (this.reintentando()) { return; }

        this.reintentando.set(true);

        // El caso de uso no falla: el repositorio traduce el error a un modelo
        this.verificarEstadoServidorUseCase.execute().subscribe({
            next: () => this.reintentando.set(false),
            error: () => this.reintentando.set(false)
        });
    }

    /** Título según el servidor haya respondido mal o no haya respondido */
    get titulo(): string {
        return this.store.salud()?.estaInalcanzable()
            ? 'No se encuentra el servidor'
            : 'El servidor no está levantado correctamente';
    }
}
