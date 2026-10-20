import { Injectable, inject } from '@angular/core';
import { Observable, tap, throwError } from 'rxjs';
import { UseCase } from '../../../base/abstracts';
import { MovimientoReporte } from '../models/movimiento-reporte.model';
import { ReportePorFechasRequest } from '../models/reporte-por-fechas-request.model';
import { ReportesRepository } from '../repositories/reportes.repository';
import { ReportesStore } from '../reportes.store';

@Injectable({ providedIn: 'root' })
export class ObtenerReportePorFechasUseCase
    implements UseCase<ReportePorFechasRequest, MovimientoReporte[]> {

    private reportesRepository = inject(ReportesRepository);
    private reportesStore = inject(ReportesStore);

    execute(params: ReportePorFechasRequest): Observable<MovimientoReporte[]> {
        // El rango se valida aquí para no gastar una llamada que la api
        // rechazaría; el componente muestra el mensaje en el diálogo global
        if (!params.esRangoValido()) {
            return throwError(() => new Error(
                'La fecha inicial debe ser anterior o igual a la fecha final.'
            ));
        }

        const request = params.withCopy({
            fechaInicial: this.aFechaHoraApi(params.fechaInicial),
            fechaFinal: this.aFechaHoraApi(params.fechaFinal)
        });

        return this.reportesRepository.obtenerPorFechas(request).pipe(
            tap(movimientos => this.reportesStore.establecer(movimientos))
        );
    }

    /**
     * Completa los segundos que el campo `datetime-local` del navegador omite.
     * El backend espera `yyyy-MM-ddTHH:mm:ss`; sin los segundos el
     * `LocalDateTime` igual parsea, pero se envía completo para no depender de
     * ese detalle.
     */
    private aFechaHoraApi(valor: string): string {
        return valor.length === 16 ? `${valor}:00` : valor;
    }
}
