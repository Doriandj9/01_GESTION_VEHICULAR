import { CommonModule } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { environment } from '../../../environments';
import { EstadoUsuario, RolUsuario } from '../../base/apiTypes';
import { aErrorApi } from '../../base/apiErrors';
import { DialogoResultadoService } from '../../base/components/dialogo-resultado/dialogo-resultado.service';
import { LoaderService } from '../../base/loadService';
import { SesionStore } from '../../auth/domain/sesion.store';
import { LogoutUseCase } from '../../auth/domain/usecases/logout.usecase';
import { ActualizarUsuarioRequest } from '../domain/models/actualizar-usuario-request.model';
import { CrearUsuarioRequest } from '../domain/models/crear-usuario-request.model';
import { Usuario } from '../domain/models/usuario.model';
import { ActualizarUsuarioUseCase } from '../domain/usecases/actualizar-usuario.usecase';
import { CrearUsuarioUseCase } from '../domain/usecases/crear-usuario.usecase';
import { ListarUsuariosUseCase } from '../domain/usecases/listar-usuarios.usecase';
import { UsuariosStore } from '../domain/usuarios.store';

// -----------------------------------------------------------
// UsuariosPage (Orquestador del módulo de usuarios)
// -----------------------------------------------------------
@Component({
    selector: 'app-usuarios',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './usuarios.page.html',
    styleUrls: ['./usuarios.page.css']
})
export class UsuariosPage implements OnInit {
    private listarUsuariosUseCase = inject(ListarUsuariosUseCase);
    private crearUsuarioUseCase = inject(CrearUsuarioUseCase);
    private actualizarUsuarioUseCase = inject(ActualizarUsuarioUseCase);
    private logoutUseCase = inject(LogoutUseCase);
    private dialogo = inject(DialogoResultadoService);
    private loader = inject(LoaderService);
    private router = inject(Router);

    /** Estado global de la sesión y de los usuarios */
    protected readonly sesion = inject(SesionStore);
    protected readonly store = inject(UsuariosStore);

    /** Identidad de la entidad, tomada de las variables de ambiente */
    protected readonly entidad = environment.entidad;

    /** Roles que ofrece el formulario */
    protected readonly roles: RolUsuario[] = ['ADMINISTRADOR', 'GUARDIA'];

    /**
     * Datos del formulario. Son `signal` porque `formularioValido` es un
     * `computed`: con campos planos el cálculo nunca se vuelve a evaluar y el
     * botón quedaría deshabilitado para siempre.
     */
    readonly nombre = signal('');
    readonly correo = signal('');
    readonly rol = signal<RolUsuario>('GUARDIA');

    /** Indica que el registro está en curso */
    readonly cargando = signal(false);

    /** Indica que se está trayendo el listado */
    readonly cargandoListado = signal(false);

    /** Código del usuario cuyo estado se está cambiando */
    readonly actualizando = signal<number | null>(null);

    /** El formulario está listo cuando el nombre y el correo tienen valor */
    readonly formularioValido = computed(() =>
        this.nombre().trim().length > 0 && this.correo().trim().length > 0
    );

    ngOnInit(): void {
        this.cargarUsuarios();
    }

    /** Trae el listado completo de usuarios */
    cargarUsuarios(): void {
        this.cargandoListado.set(true);

        this.listarUsuariosUseCase.execute().subscribe({
            next: () => this.cargandoListado.set(false),
            error: (fallo: unknown) => {
                this.cargandoListado.set(false);
                this.dialogo.error(aErrorApi(fallo), 'No se pudo cargar el listado');
            }
        });
    }

    /** Registra un usuario nuevo */
    onFormSubmit(): void {
        if (this.cargando() || !this.formularioValido()) { return; }

        this.cargando.set(true);
        this.loader.display(true);

        const request = new CrearUsuarioRequest(this.nombre(), this.correo(), this.rol());

        this.crearUsuarioUseCase.execute(request).subscribe({
            next: usuario => {
                this.finalizar();
                this.store.agregar(usuario);
                this.limpiarFormulario();
                this.dialogo.exito(
                    `El usuario ${usuario.nombres} fue registrado con el rol ${usuario.rol}. Debe cambiar su clave al ingresar por primera vez.`,
                    'Usuario registrado'
                );
            },
            error: (fallo: unknown) => {
                // El diálogo muestra el mensaje de la api y sus validaciones
                this.finalizar();
                this.dialogo.error(aErrorApi(fallo), 'No se pudo registrar el usuario');
            }
        });
    }

    /** Cambia el estado de un usuario ya registrado */
    cambiarEstado(usuario: Usuario, estado: EstadoUsuario): void {
        if (this.actualizando() !== null || usuario.estado === estado) { return; }

        this.actualizando.set(usuario.codUsuarios);
        this.loader.display(true);

        const request = new ActualizarUsuarioRequest(usuario.codUsuarios, undefined, undefined, undefined, estado);

        this.actualizarUsuarioUseCase.execute(request).subscribe({
            next: actualizado => {
                this.terminarActualizacion();
                this.store.reemplazar(actualizado);
                this.dialogo.exito(
                    `El usuario ${actualizado.nombres} quedó en estado ${actualizado.estado}.`,
                    'Estado actualizado'
                );
            },
            error: (fallo: unknown) => {
                this.terminarActualizacion();
                this.dialogo.error(aErrorApi(fallo), 'No se pudo actualizar el usuario');
            }
        });
    }

    /** Vuelve al panel de administración */
    irAlDashboard(): void {
        this.router.navigate(['/dashboard']);
    }

    /** Cierra la sesión y vuelve al login */
    cerrarSesion(): void {
        this.loader.display(true);

        this.logoutUseCase.execute().subscribe({
            next: () => this.volverAlLogin(),
            error: () => this.volverAlLogin()
        });
    }

    /** Indica si la fila del usuario está esperando respuesta de la api */
    filaEnEspera(usuario: Usuario): boolean {
        return this.actualizando() === usuario.codUsuarios;
    }

    /** Clases del distintivo según el estado del usuario */
    clasesEstado(estado: EstadoUsuario | null): string {
        if (estado === 'ACTIVO') {
            return 'bg-primario/10 text-primario-oscuro';
        }

        if (estado === 'INICIAL') {
            return 'bg-amber-100 text-amber-700';
        }

        return 'bg-carbon/10 text-carbon/60';
    }

    /** Texto del distintivo; el listado de la api no informa el estado */
    textoEstado(estado: EstadoUsuario | null): string {
        return estado ?? 'sin dato';
    }

    private limpiarFormulario(): void {
        this.nombre.set('');
        this.correo.set('');
        this.rol.set('GUARDIA');
    }

    private finalizar(): void {
        this.cargando.set(false);
        this.loader.display(false);
    }

    private terminarActualizacion(): void {
        this.actualizando.set(null);
        this.loader.display(false);
    }

    private volverAlLogin(): void {
        this.loader.display(false);
        this.router.navigate(['/login']);
    }
}
