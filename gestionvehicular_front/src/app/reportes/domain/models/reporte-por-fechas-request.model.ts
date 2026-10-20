/**
 * Petición del reporte por rango (`GET /movimientos/reporte/por-fechas`).
 * Los dos campos son obligatorios para la api y viajan como `date-time` sin
 * zona (`yyyy-MM-ddTHH:mm:ss`), que es el formato que lee el `LocalDateTime`
 * del backend.
 */
export class ReportePorFechasRequest {
    constructor(
        public readonly fechaInicial: string,
        public readonly fechaFinal: string
    ) { }

    /** Compara por valor, no por referencia */
    equals(otro: ReportePorFechasRequest): boolean {
        return this.fechaInicial === otro.fechaInicial
            && this.fechaFinal === otro.fechaFinal;
    }

    /** Devuelve una nueva instancia con los campos indicados */
    withCopy(cambios: Partial<ReportePorFechasRequest>): ReportePorFechasRequest {
        return new ReportePorFechasRequest(
            cambios.fechaInicial ?? this.fechaInicial,
            cambios.fechaFinal ?? this.fechaFinal
        );
    }

    /** Indica si el rango está completo y en orden */
    esRangoValido(): boolean {
        if (!this.fechaInicial || !this.fechaFinal) { return false; }

        return this.fechaInicial <= this.fechaFinal;
    }
}
