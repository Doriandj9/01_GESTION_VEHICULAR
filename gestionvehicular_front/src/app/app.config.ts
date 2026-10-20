import { provideHttpClient, withInterceptors } from '@angular/common/http';
import {
  ApplicationConfig,
  importProvidersFrom,
  inject,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners
} from '@angular/core';
import { provideRouter } from '@angular/router';
import { DataModule } from './auth/data/data.module';
import { authInterceptor } from './auth/data/auth.interceptor';
import { EstadoServidorDataModule } from './estado-servidor/data/data.module';
import { VerificarEstadoServidorUseCase } from './estado-servidor/domain/usecases/verificar-estado-servidor.usecase';
import { ParqueaderosDataModule } from './parqueaderos/data/data.module';
import { RegistroVehicularDataModule } from './registro-vehicular/data/data.module';
import { ReportesDataModule } from './reportes/data/data.module';
import { UsuariosDataModule } from './usuarios/data/data.module';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideHttpClient(withInterceptors([authInterceptor])),
    provideRouter(routes),
    // Los casos de uso y el interceptor son de raíz, así que el enlace de los
    // repositorios de cada funcionalidad también debe estar en el injector raíz
    importProvidersFrom(
      DataModule,
      UsuariosDataModule,
      ParqueaderosDataModule,
      RegistroVehicularDataModule,
      ReportesDataModule,
      EstadoServidorDataModule
    ),
    // Chequeo de salud del backend al arrancar. No se devuelve el observable a
    // propósito: la aplicación no debe quedarse en blanco esperando al servidor.
    // `EstadoServidorComponent` tapa la pantalla si el chequeo sale mal.
    provideAppInitializer(() => {
      inject(VerificarEstadoServidorUseCase).execute().subscribe();
    })
  ]
};
