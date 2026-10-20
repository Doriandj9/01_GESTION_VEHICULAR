import { Injectable, inject } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { MovimientoReporte } from '../models/movimiento-reporte.model';
import { ReporteTodosRequest } from '../models/reporte-todos-request.model';
import { ReportesRepository } from '../repositories/reportes.repository';
import { ReportesStore } from '../reportes.store';

@Injectable({ providedIn: 'root' })
export class ObtenerReporteTodosUseCase implements UseCase<ReporteTodosRequest, MovimientoReporte[]> {
    private reportesRepository = inject(ReportesRepository);
    private reportesStore = inject(ReportesStore);

    execute(params: ReporteTodosRequest): Observable<MovimientoReporte[]> {
        // `cantidad` es un `int32` positivo: un cero o un negativo no acota nada,
        // así que se descarta antes de armar la petición
        const request = params.withCopy({
            cantidad: params.cantidad !== null && params.cantidad > 0 ? params.cantidad : null
        });

        // El reporte es la fuente de verdad: reemplaza lo que haya en memoria
        return this.reportesRepository.obtenerTodos(request).pipe(
            tap(movimientos => this.reportesStore.establecer(movimientos))
        );
    }
}
