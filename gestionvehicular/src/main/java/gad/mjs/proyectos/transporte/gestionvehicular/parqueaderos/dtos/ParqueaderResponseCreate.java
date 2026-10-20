package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.estados.EstadosParqueadero;

import java.math.BigDecimal;

public record ParqueaderResponseCreate(
        Long codParqueadero,
        String nombre,
        String callePrincipal,
        String calleSecundaria,
        BigDecimal latitud,
        BigDecimal longitud,
        String urlDireccion,
        EstadosParqueadero estado
) {
}
