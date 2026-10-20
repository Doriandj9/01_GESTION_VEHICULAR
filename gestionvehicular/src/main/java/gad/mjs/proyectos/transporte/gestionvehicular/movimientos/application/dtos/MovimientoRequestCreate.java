package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.tipo.TiposMovimiento;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record MovimientoRequestCreate(
        @NotNull @NotEmpty
        String data,
        TiposMovimiento tipo,
        BigDecimal latitud,
        BigDecimal longitud
) {
}
