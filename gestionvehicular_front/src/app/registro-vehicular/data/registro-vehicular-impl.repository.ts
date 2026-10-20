import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments';
import { VehiculoResponse } from '../../base/apiTypes';
import { ActualizarVehiculoRequest } from '../domain/models/actualizar-vehiculo-request.model';
import { CrearVehiculoRequest } from '../domain/models/crear-vehiculo-request.model';
import { Vehiculo } from '../domain/models/vehiculo.model';
import { RegistroVehicularRepository } from '../domain/repositories/registro-vehicular.repository';

@Injectable()
export class RegistroVehicularImplRepository extends RegistroVehicularRepository {
    private http = inject(HttpClient);
    private urlEndpoint = `${environment.api.url}${environment.api.version}/registro_vehicular`;

    override listar(): Observable<Vehiculo[]> {
        return this.http.get<VehiculoResponse[]>(this.urlEndpoint).pipe(
            map(responseApi => responseApi.map(item => this.aVehiculo(item)))
        );
    }

    override obtenerPorId(codVehiculo: number): Observable<Vehiculo> {
        return this.http.get<VehiculoResponse>(`${this.urlEndpoint}/${codVehiculo}`).pipe(
            map(responseApi => this.aVehiculo(responseApi))
        );
    }

    override crear(params: CrearVehiculoRequest): Observable<Vehiculo> {
        const cuerpo = {
            placa: params.placa,
            conductor: params.conductor,
            codParqueadero: params.codParqueadero
        };

        // La api genera el código QR del vehículo y lo devuelve en base64
        return this.http.post<VehiculoResponse>(this.urlEndpoint, cuerpo).pipe(
            map(responseApi => this.aVehiculo(responseApi))
        );
    }

    override actualizar(params: ActualizarVehiculoRequest): Observable<Vehiculo> {
        // Solo se envían los campos que traen valor
        const cuerpo: Record<string, string | number> = {};

        if (params.placa) { cuerpo['placa'] = params.placa; }
        if (params.conductor) { cuerpo['conductor'] = params.conductor; }
        if (params.estado) { cuerpo['estado'] = params.estado; }
        if (params.codParqueadero) { cuerpo['codParqueadero'] = params.codParqueadero; }

        const url = `${this.urlEndpoint}/${params.codVehiculo}`;

        return this.http.put<VehiculoResponse>(url, cuerpo).pipe(
            map(responseApi => this.aVehiculo(responseApi))
        );
    }

    /** Mapea la respuesta de la api al modelo del dominio */
    private aVehiculo(responseApi: VehiculoResponse): Vehiculo {
        return new Vehiculo(
            responseApi.codVehiculo,
            responseApi.placa,
            responseApi.conductor,
            responseApi.estado,
            responseApi.codParqueadero,
            responseApi.qrCodeBase64 ?? ''
        );
    }
}
