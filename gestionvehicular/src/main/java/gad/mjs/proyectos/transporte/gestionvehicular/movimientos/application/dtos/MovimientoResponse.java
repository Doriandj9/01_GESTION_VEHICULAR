package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.estados.EstadosMovimientos;

import java.time.Instant;

public record MovimientoResponse(
        Instant registro,
        EstadosMovimientos estado
) {
}
