import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { UsuariosRepository } from '../domain/repositories/usuarios.repository';
import { UsuariosImplRepository } from './usuarios-impl.repository';

@NgModule({
    imports: [CommonModule],
    providers: [
        { provide: UsuariosRepository, useClass: UsuariosImplRepository }
    ]
})
export class UsuariosDataModule { }
