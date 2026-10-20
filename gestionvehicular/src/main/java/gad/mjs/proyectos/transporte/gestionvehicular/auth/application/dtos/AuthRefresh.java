package gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record AuthRefresh(
        @NotNull @NotEmpty
        String token
) {
}
