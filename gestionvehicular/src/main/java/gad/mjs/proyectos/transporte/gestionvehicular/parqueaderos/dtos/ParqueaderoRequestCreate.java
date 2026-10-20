package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos;


import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record ParqueaderoRequestCreate(
        @NotNull @NotEmpty
        String nombre,
        @NotNull @NotEmpty
        String callePrincipal,
        String calleSecundaria,
        BigDecimal latitud,
        BigDecimal longitud,
        String urlDireccion
) {
}
