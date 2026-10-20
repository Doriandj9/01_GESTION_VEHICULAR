import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments';
import { MovimientoReporteResponse } from '../../base/apiTypes';
import { MovimientoReporte } from '../domain/models/movimiento-reporte.model';
import { ReportePorFechasRequest } from '../domain/models/reporte-por-fechas-request.model';
import { ReporteTodosRequest } from '../domain/models/reporte-todos-request.model';
import { ReportesRepository } from '../domain/repositories/reportes.repository';

@Injectable()
export class ReportesImplRepository extends ReportesRepository {
    private http = inject(HttpClient);
    private urlEndpoint = `${environment.api.url}${environment.api.version}/movimientos/reporte`;

    override obtenerTodos(params: ReporteTodosRequest): Observable<MovimientoReporte[]> {
        // `cantidad` es opcional: si no viene, la api devuelve el histórico completo
        let consulta = new HttpParams();

        if (params.cantidad !== null) {
            consulta = consulta.set('cantidad', params.cantidad);
        }

        return this.http
            .get<MovimientoReporteResponse[]>(`${this.urlEndpoint}/todos`, { params: consulta })
            .pipe(map(responseApi => responseApi.map(item => this.aMovimiento(item))));
    }

    override obtenerPorFechas(params: ReportePorFechasRequest): Observable<MovimientoReporte[]> {
        // Los dos parámetros son obligatorios para la api
        const consulta = new HttpParams()
            .set('fechaInicial', params.fechaInicial)
            .set('fechaFinal', params.fechaFinal);

        return this.http
            .get<MovimientoReporteResponse[]>(`${this.urlEndpoint}/por-fechas`, { params: consulta })
            .pipe(map(responseApi => responseApi.map(item => this.aMovimiento(item))));
    }

    /** Mapea la respuesta de la api al modelo del dominio */
    private aMovimiento(responseApi: MovimientoReporteResponse): MovimientoReporte {
        return new MovimientoReporte(
            responseApi.codUsuarioRegistro,
            responseApi.nombreUsuarioRegistro,
            responseApi.latitudRegistro ?? null,
            responseApi.longitudRegistro ?? null,
            responseApi.fechaRegistro,
            responseApi.tipoMovimiento,
            responseApi.codVehiculo,
            responseApi.placa,
            responseApi.conductor,
            responseApi.codParqueadero,
            responseApi.nombreParqueadero,
            responseApi.callePrincipalParqueadero,
            responseApi.calleSecundariaParqueadero ?? '',
            responseApi.latitudParqueadero ?? null,
            responseApi.longitudParqueadero ?? null,
            responseApi.urlDireccionParqueadero ?? ''
        );
    }
}
