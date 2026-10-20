/**
 * Petición del reporte completo (`GET /movimientos/reporte/todos`).
 * `cantidad` es el único acotador que ofrece la api: trae los últimos N
 * movimientos. Con `null` la api devuelve todo lo que haya.
 */
export class ReporteTodosRequest {
    constructor(
        public readonly cantidad: number | null = null
    ) { }

    /** Compara por valor, no por referencia */
    equals(otro: ReporteTodosRequest): boolean {
        return this.cantidad === otro.cantidad;
    }

    /** Devuelve una nueva instancia con los campos indicados */
    withCopy(cambios: Partial<ReporteTodosRequest>): ReporteTodosRequest {
        return new ReporteTodosRequest(
            cambios.cantidad !== undefined ? cambios.cantidad : this.cantidad
        );
    }
}
