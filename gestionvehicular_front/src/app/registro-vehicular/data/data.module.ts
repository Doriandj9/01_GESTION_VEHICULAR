import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { RegistroVehicularRepository } from '../domain/repositories/registro-vehicular.repository';
import { RegistroVehicularImplRepository } from './registro-vehicular-impl.repository';

@NgModule({
    imports: [CommonModule],
    providers: [
        { provide: RegistroVehicularRepository, useClass: RegistroVehicularImplRepository }
    ]
})
export class RegistroVehicularDataModule { }
