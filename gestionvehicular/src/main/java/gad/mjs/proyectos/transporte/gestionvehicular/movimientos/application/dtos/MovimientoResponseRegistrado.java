package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.tipo.TiposMovimiento;

import java.math.BigDecimal;
import java.time.Instant;

public record MovimientoResponseRegistrado(
        Long codUsuarioRegistro,
        String nombreUsuarioRegistro,
        BigDecimal latitudRegistro,
        BigDecimal longitudRegistro,
        Instant fechaRegistro,
        TiposMovimiento tipoMovimiento,
        Long codVehiculo,
        String placa,
        String conductor
) {
}
