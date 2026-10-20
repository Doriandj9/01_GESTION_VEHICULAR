import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { DialogoResultadoService } from './dialogo-resultado.service';

// -----------------------------------------------------------
// DialogoResultadoComponent (Diálogo global de éxito y error)
// -----------------------------------------------------------
/**
 * Se monta una única vez en la raíz de la aplicación (`app.html`) y reacciona
 * al estado de `DialogoResultadoService`. No recibe entradas: las pantallas
 * solo llaman al servicio.
 */
@Component({
    selector: 'app-dialogo-resultado',
    standalone: true,
    imports: [CommonModule],
    templateUrl: './dialogo-resultado.component.html',
    styleUrls: ['./dialogo-resultado.component.css']
})
export class DialogoResultadoComponent {
    protected readonly dialogo = inject(DialogoResultadoService);

    /** Título por defecto cuando la pantalla no envía uno */
    protected get titulo(): string {
        const resultado = this.dialogo.resultado();

        if (!resultado) { return ''; }

        return resultado.titulo ?? (resultado.tipo === 'exito' ? 'Operación exitosa' : 'No se pudo completar');
    }

    cerrar(): void {
        this.dialogo.cerrar();
    }
}
