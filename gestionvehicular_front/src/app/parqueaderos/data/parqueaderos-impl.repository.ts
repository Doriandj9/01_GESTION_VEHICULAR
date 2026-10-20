import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments';
import { EstadoOperativo, ParqueaderoResponse } from '../../base/apiTypes';
import { ActualizarParqueaderoRequest } from '../domain/models/actualizar-parqueadero-request.model';
import { CrearParqueaderoRequest } from '../domain/models/crear-parqueadero-request.model';
import { Parqueadero } from '../domain/models/parqueadero.model';
import { ParqueaderosRepository } from '../domain/repositories/parqueaderos.repository';

@Injectable()
export class ParqueaderosImplRepository extends ParqueaderosRepository {
    private http = inject(HttpClient);
    private urlEndpoint = `${environment.api.url}${environment.api.version}/parqueaderos`;

    override listar(): Observable<Parqueadero[]> {
        // Ninguna respuesta de parqueaderos incluye el estado
        return this.http.get<ParqueaderoResponse[]>(this.urlEndpoint).pipe(
            map(responseApi => responseApi.map(item => this.aParqueadero(item, null)))
        );
    }

    override crear(params: CrearParqueaderoRequest): Observable<Parqueadero> {
        const cuerpo: Record<string, string | number> = {
            nombre: params.nombre,
            callePrincipal: params.callePrincipal
        };

        // Los campos opcionales solo viajan si tienen valor
        if (params.calleSecundaria) { cuerpo['calleSecundaria'] = params.calleSecundaria; }
        if (params.latitud !== null) { cuerpo['latitud'] = params.latitud; }
        if (params.longitud !== null) { cuerpo['longitud'] = params.longitud; }
        if (params.urlDireccion) { cuerpo['urlDireccion'] = params.urlDireccion; }

        return this.http.post<ParqueaderoResponse>(this.urlEndpoint, cuerpo).pipe(
            map(responseApi => this.aParqueadero(responseApi, null))
        );
    }

    override actualizar(params: ActualizarParqueaderoRequest): Observable<Parqueadero> {
        // Solo se envían los campos que traen valor
        const cuerpo: Record<string, string | number> = {};

        if (params.nombre) { cuerpo['nombre'] = params.nombre; }
        if (params.callePrincipal) { cuerpo['callePrincipal'] = params.callePrincipal; }
        if (params.calleSecundaria) { cuerpo['calleSecundaria'] = params.calleSecundaria; }
        if (params.latitud !== undefined) { cuerpo['latitud'] = params.latitud; }
        if (params.longitud !== undefined) { cuerpo['longitud'] = params.longitud; }
        if (params.urlDireccion) { cuerpo['urlDireccion'] = params.urlDireccion; }
        if (params.estado) { cuerpo['estado'] = params.estado; }

        const url = `${this.urlEndpoint}/${params.codParqueadero}`;

        // La respuesta tampoco trae el estado, así que se conserva el que se
        // acaba de enviar: es el único dato fiable que tenemos de él
        return this.http.put<ParqueaderoResponse>(url, cuerpo).pipe(
            map(responseApi => this.aParqueadero(responseApi, params.estado ?? null))
        );
    }

    /** Mapea la respuesta de la api al modelo del dominio */
    private aParqueadero(responseApi: ParqueaderoResponse, estado: EstadoOperativo | null): Parqueadero {
        return new Parqueadero(
            responseApi.codParqueadero,
            responseApi.nombre,
            responseApi.callePrincipal,
            responseApi.calleSecundaria ?? '',
            responseApi.latitud ?? null,
            responseApi.longitud ?? null,
            responseApi.urlDireccion ?? '',
            responseApi.estado
        );
    }
}
