import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments';
import { UsuarioCreadoResponse, UsuarioResponse } from '../../base/apiTypes';
import { ActualizarUsuarioRequest } from '../domain/models/actualizar-usuario-request.model';
import { CrearUsuarioRequest } from '../domain/models/crear-usuario-request.model';
import { Usuario } from '../domain/models/usuario.model';
import { UsuariosRepository } from '../domain/repositories/usuarios.repository';

@Injectable()
export class UsuariosImplRepository extends UsuariosRepository {
    private http = inject(HttpClient);
    private urlEndpoint = `${environment.api.url}${environment.api.version}/usuarios`;

    override listar(): Observable<Usuario[]> {
        // El listado comparte el esquema de la creación: no incluye el estado
        return this.http.get<UsuarioCreadoResponse[]>(this.urlEndpoint).pipe(
            map(responseApi => responseApi.map(item => new Usuario(
                item.codUsuario,
                item.nombres,
                item.correo,
                item.rol,
                item?.estado ?? null
            )))
        );
    }

    override crear(params: CrearUsuarioRequest): Observable<Usuario> {
        const cuerpo = { nombre: params.nombre, correo: params.correo, rol: params.rol };

        // La respuesta no trae el estado: todo usuario nuevo nace en INICIAL
        return this.http.post<UsuarioCreadoResponse>(this.urlEndpoint, cuerpo).pipe(
            map(responseApi => new Usuario(
                responseApi.codUsuario,
                responseApi.nombres,
                responseApi.correo,
                responseApi.rol,
                'INICIAL'
            ))
        );
    }

    override actualizar(params: ActualizarUsuarioRequest): Observable<Usuario> {
        // Solo se envían los campos que traen valor
        const cuerpo: Record<string, string> = {};

        if (params.nombres) { cuerpo['nombres'] = params.nombres; }
        if (params.correo) { cuerpo['correo'] = params.correo; }
        if (params.rol) { cuerpo['rol'] = params.rol; }
        if (params.estado) { cuerpo['estado'] = params.estado; }

        const url = `${this.urlEndpoint}/${params.codUsuarios}`;

        // Aquí el rol llega como objeto `{ codRol, rol }`, se aplana al modelo
        return this.http.put<UsuarioResponse>(url, cuerpo).pipe(
            map(responseApi => new Usuario(
                responseApi.codUsuarios,
                responseApi.nombres,
                responseApi.correo,
                responseApi.rol?.rol ?? 'GUARDIA',
                responseApi.estado
            ))
        );
    }
}
