import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { AuthRepository } from '../domain/repositories/auth.repository';
import { AuthImplRepository } from './auth-impl.repository';

@NgModule({
    imports: [CommonModule],
    providers: [
        { provide: AuthRepository, useClass: AuthImplRepository }
    ]
})
export class DataModule { }
