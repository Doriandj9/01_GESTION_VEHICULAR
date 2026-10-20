import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { DialogoResultadoComponent } from './base/components/dialogo-resultado/dialogo-resultado.component';
import { EstadoServidorComponent } from './estado-servidor/presentation/estado-servidor.component';

@Component({
  imports: [RouterOutlet, DialogoResultadoComponent, EstadoServidorComponent],
  selector: 'app-root',
  styleUrl: './app.css',
  templateUrl: './app.html',
})
export class App {
  protected readonly title = signal('gestionvehicular_front');
}
