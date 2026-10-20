import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { ParqueaderosRepository } from '../domain/repositories/parqueaderos.repository';
import { ParqueaderosImplRepository } from './parqueaderos-impl.repository';

@NgModule({
    imports: [CommonModule],
    providers: [
        { provide: ParqueaderosRepository, useClass: ParqueaderosImplRepository }
    ]
})
export class ParqueaderosDataModule { }
