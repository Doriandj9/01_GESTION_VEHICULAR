import { Observable } from 'rxjs';
import { MovimientoReporte } from '../models/movimiento-reporte.model';
import { ReportePorFechasRequest } from '../models/reporte-por-fechas-request.model';
import { ReporteTodosRequest } from '../models/reporte-todos-request.model';

export abstract class ReportesRepository {
    // Reporte de todos los movimientos, opcionalmente solo los últimos N
    abstract obtenerTodos(params: ReporteTodosRequest): Observable<MovimientoReporte[]>;

    // Reporte de los movimientos ocurridos dentro de un rango de fechas
    abstract obtenerPorFechas(params: ReportePorFechasRequest): Observable<MovimientoReporte[]>;
}
