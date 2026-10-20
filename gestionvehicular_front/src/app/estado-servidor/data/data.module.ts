import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { EstadoServidorRepository } from '../domain/repositories/estado-servidor.repository';
import { EstadoServidorImplRepository } from './estado-servidor-impl.repository';

@NgModule({
    imports: [CommonModule],
    providers: [
        { provide: EstadoServidorRepository, useClass: EstadoServidorImplRepository }
    ]
})
export class EstadoServidorDataModule { }
