import { Routes } from '@angular/router';
import { claveInicialGuard, rolGuard, sesionGuard } from './auth/presentation/guards/auth.guards';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./auth/presentation/login.page').then(m => m.LoginPage)
  },
  {
    // Cambio obligatorio de la clave inicial
    path: 'cambiar-clave',
    canActivate: [claveInicialGuard],
    loadComponent: () => import('./auth/presentation/cambiar-clave.page').then(m => m.CambiarClavePage)
  },
  {
    // Solo el rol ADMINISTRADOR y con la clave ya cambiada
    path: 'dashboard',
    canActivate: [sesionGuard, rolGuard('ADMINISTRADOR')],
    loadComponent: () => import('./dashboard/presentation/dashboard.page').then(m => m.DashboardPage)
  },
  {
    // Módulo de usuarios: solo el rol ADMINISTRADOR
    path: 'usuarios',
    canActivate: [sesionGuard, rolGuard('ADMINISTRADOR')],
    loadComponent: () => import('./usuarios/presentation/usuarios.page').then(m => m.UsuariosPage)
  },
  {
    // Módulo de parqueaderos: solo el rol ADMINISTRADOR
    path: 'parqueaderos',
    canActivate: [sesionGuard, rolGuard('ADMINISTRADOR')],
    loadComponent: () => import('./parqueaderos/presentation/parqueaderos.page').then(m => m.ParqueaderosPage)
  },
  {
    // Módulo de registro vehicular: solo el rol ADMINISTRADOR
    path: 'registro-vehicular',
    canActivate: [sesionGuard, rolGuard('ADMINISTRADOR')],
    loadComponent: () => import('./registro-vehicular/presentation/registro-vehicular.page').then(m => m.RegistroVehicularPage)
  },
  {
    // Módulo de reportes de movimientos: solo el rol ADMINISTRADOR
    path: 'reportes',
    canActivate: [sesionGuard, rolGuard('ADMINISTRADOR')],
    loadComponent: () => import('./reportes/presentation/reportes.page').then(m => m.ReportesPage)
  },
  { path: '', pathMatch: 'full', redirectTo: 'login' },
  { path: '**', redirectTo: 'login' }
];
