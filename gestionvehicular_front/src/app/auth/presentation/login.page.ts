import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { environment } from '../../../environments';
import { ErrorApi, aErrorApi, erroresDeValidacion } from '../../base/apiErrors';
import { LoaderService } from '../../base/loadService';
import { LoginRequest } from '../domain/models/login-request.model';
import { UsuarioDetalle } from '../domain/models/usuario-detalle.model';
import { SesionStore } from '../domain/sesion.store';
import { LoginUseCase } from '../domain/usecases/login.usecase';

// -----------------------------------------------------------
// LoginPage (Orquestador del inicio de sesión)
// -----------------------------------------------------------
@Component({
    selector: 'app-login',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './login.page.html',
    styleUrls: ['./login.page.css']
})
export class LoginPage {
    private loginUseCase = inject(LoginUseCase);
    private loader = inject(LoaderService);
    private router = inject(Router);

    /** Estado global de la sesión */
    protected readonly sesion = inject(SesionStore);

    /** Identidad de la entidad, tomada de las variables de ambiente */
    protected readonly entidad = environment.entidad;

    /** Datos del formulario */
    correo = '';
    password = '';

    /** Error devuelto por la api */
    readonly error = signal<ErrorApi | null>(null);

    /** Indica que la petición está en curso */
    readonly cargando = signal(false);

    /** Validaciones por campo devueltas por la api */
    readonly validaciones = computed(() => {
        const error = this.error();
        return error ? erroresDeValidacion(error) : [];
    });

    onFormSubmit(): void {
        if (this.cargando()) { return; }

        this.error.set(null);
        this.sesion.descartarAvisoExpiracion();
        this.cargando.set(true);
        this.loader.display(true);

        const request = new LoginRequest(this.correo.trim(), this.password);

        this.loginUseCase.execute(request).subscribe({
            next: usuario => {
                // El caso de uso ya guardó los tokens y el usuario
                this.finalizar();
                this.password = '';
                this.navegarSegunUsuario(usuario);
            },
            error: (fallo: unknown) => {
                // Se muestra el mensaje de la api y se limpia la clave
                this.finalizar();
                this.password = '';
                this.error.set(aErrorApi(fallo));
            }
        });
    }

    /** Oculta el aviso de sesión expirada */
    descartarAvisoExpiracion(): void {
        this.sesion.descartarAvisoExpiracion();
    }

    /** Lleva al usuario a su pantalla según su estado y su rol */
    private navegarSegunUsuario(usuario: UsuarioDetalle): void {
        // Con la clave inicial no se puede entrar a ninguna otra pantalla
        if (usuario.estado === 'INICIAL') {
            this.router.navigate(['/cambiar-clave']);
            return;
        }

        if (usuario.esAdministrador()) {
            this.router.navigate(['/dashboard']);
            return;
        }

        // Los demás roles todavía no tienen pantalla asignada
        this.error.set({
            message: 'Su rol aún no tiene una pantalla asignada en el sistema.',
            errors: {}
        });
    }

    /** Cierra el estado de carga */
    private finalizar(): void {
        this.cargando.set(false);
        this.loader.display(false);
    }
}
