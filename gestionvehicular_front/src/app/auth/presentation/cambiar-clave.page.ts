import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { environment } from '../../../environments';
import { ErrorApi, aErrorApi, erroresDeValidacion } from '../../base/apiErrors';
import { LoaderService } from '../../base/loadService';
import { ChangePasswordRequest } from '../domain/models/change-password-request.model';
import { claveEsValida, evaluarClave, fortalezaClave } from '../domain/reglas-clave';
import { SesionStore } from '../domain/sesion.store';
import { ChangePasswordUseCase } from '../domain/usecases/change-password.usecase';
import { LogoutUseCase } from '../domain/usecases/logout.usecase';

// -----------------------------------------------------------
// CambiarClavePage (Cambio obligatorio de la clave inicial)
// -----------------------------------------------------------
@Component({
    selector: 'app-cambiar-clave',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './cambiar-clave.page.html',
    styleUrls: ['./cambiar-clave.page.css']
})
export class CambiarClavePage {
    private changePasswordUseCase = inject(ChangePasswordUseCase);
    private logoutUseCase = inject(LogoutUseCase);
    private loader = inject(LoaderService);
    private router = inject(Router);

    protected readonly sesion = inject(SesionStore);
    protected readonly entidad = environment.entidad;

    /** Datos del formulario */
    readonly claveActual = signal('');
    readonly claveNueva = signal('');
    readonly claveRepetida = signal('');

    /** Error devuelto por la api */
    readonly error = signal<ErrorApi | null>(null);

    /** Indica que la petición está en curso */
    readonly cargando = signal(false);

    /** Métricas de la clave nueva */
    readonly reglas = computed(() => evaluarClave(this.claveNueva()));

    /** Nivel de fortaleza de 0 a 3 */
    readonly fortaleza = computed(() => fortalezaClave(this.claveNueva()));

    /** Indica si las dos claves nuevas coinciden */
    readonly clavesCoinciden = computed(() =>
        this.claveRepetida().length > 0 && this.claveNueva() === this.claveRepetida()
    );

    /** La clave nueva no puede ser igual a la actual */
    readonly claveEsDistinta = computed(() =>
        this.claveNueva().length > 0 && this.claveNueva() !== this.claveActual()
    );

    /** Habilita el envío solo cuando todo está correcto */
    readonly puedeEnviar = computed(() =>
        this.claveActual().length > 0
        && claveEsValida(this.claveNueva())
        && this.clavesCoinciden()
        && this.claveEsDistinta()
        && !this.cargando()
    );

    /** Validaciones por campo devueltas por la api */
    readonly validaciones = computed(() => {
        const error = this.error();
        return error ? erroresDeValidacion(error) : [];
    });

    onFormSubmit(): void {
        if (!this.puedeEnviar()) { return; }

        this.error.set(null);
        this.cargando.set(true);
        this.loader.display(true);

        const correo = this.sesion.usuario()?.correo ?? '';
        const request = new ChangePasswordRequest(
            correo,
            this.claveActual(),
            this.claveNueva()
        );

        this.changePasswordUseCase.execute(request).subscribe({
            next: () => {
                this.finalizar();
                this.router.navigate(['/dashboard']);
            },
            error: (fallo: unknown) => {
                // Se muestra el mensaje de la api y sus validaciones de campo
                this.finalizar();
                this.error.set(aErrorApi(fallo));
                this.claveActual.set('');
                this.claveNueva.set('');
                this.claveRepetida.set('');
            }
        });
    }

    /** Cierra la sesión y vuelve al login */
    cerrarSesion(): void {
        this.loader.display(true);

        this.logoutUseCase.execute().subscribe({
            next: () => this.volverAlLogin(),
            error: () => this.volverAlLogin()
        });
    }

    private volverAlLogin(): void {
        this.loader.display(false);
        this.router.navigate(['/login']);
    }

    private finalizar(): void {
        this.cargando.set(false);
        this.loader.display(false);
    }
}
