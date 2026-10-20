package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.mappers;

import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.Movimiento;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.estados.EstadosMovimientos;
import org.springframework.stereotype.Component;

@Component
public class MovimientoApplicationMapper {


    public MovimientoResponse toResponse(Movimiento movimiento, EstadosMovimientos estado) {
        return new  MovimientoResponse(
                movimiento.getFechaHoraRegistro(),
                estado
        );
    }
}
