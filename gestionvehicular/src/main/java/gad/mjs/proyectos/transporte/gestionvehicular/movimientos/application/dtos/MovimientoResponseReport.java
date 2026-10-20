package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.tipo.TiposMovimiento;

import java.math.BigDecimal;
import java.time.Instant;

public record MovimientoResponseReport(
        Long codUsuarioRegistro,
        String nombreUsuarioRegistro,
        BigDecimal latitudRegistro,
        BigDecimal longitudRegistro,
        Instant fechaRegistro,
        TiposMovimiento tipoMovimiento,
        Long codVehiculo,
        String placa,
        String conductor,
        Long codParqueadero,
        String nombreParqueadero,
        String callePrincipalParqueadero,
        String calleSecundariaParqueadero,
        BigDecimal latitudParqueadero,
        BigDecimal longitudParqueadero,
        String urlDireccionParqueadero
) {
}
