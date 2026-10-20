import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { ReportesRepository } from '../domain/repositories/reportes.repository';
import { ReportesImplRepository } from './reportes-impl.repository';

@NgModule({
    imports: [CommonModule],
    providers: [
        { provide: ReportesRepository, useClass: ReportesImplRepository }
    ]
})
export class ReportesDataModule { }
