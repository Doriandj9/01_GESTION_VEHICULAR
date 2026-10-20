import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { environment } from '../../../environments';
import { LoaderService } from '../../base/loadService';
import { SesionStore } from '../../auth/domain/sesion.store';
import { LogoutUseCase } from '../../auth/domain/usecases/logout.usecase';

// -----------------------------------------------------------
// DashboardPage (Pantalla principal del rol ADMINISTRADOR)
// -----------------------------------------------------------
@Component({
    selector: 'app-dashboard',
    standalone: true,
    imports: [CommonModule],
    templateUrl: './dashboard.page.html',
    styleUrls: ['./dashboard.page.css']
})
export class DashboardPage {
    private logoutUseCase = inject(LogoutUseCase);
    private loader = inject(LoaderService);
    private router = inject(Router);

    protected readonly sesion = inject(SesionStore);
    protected readonly entidad = environment.entidad;

    /** Abre el módulo de usuarios */
    irAUsuarios(): void {
        this.router.navigate(['/usuarios']);
    }

    /** Abre el módulo de parqueaderos */
    irAParqueaderos(): void {
        this.router.navigate(['/parqueaderos']);
    }

    /** Abre el módulo de registro vehicular */
    irARegistroVehicular(): void {
        this.router.navigate(['/registro-vehicular']);
    }

    /** Abre el módulo de reportes de movimientos */
    irAReportes(): void {
        this.router.navigate(['/reportes']);
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
}
