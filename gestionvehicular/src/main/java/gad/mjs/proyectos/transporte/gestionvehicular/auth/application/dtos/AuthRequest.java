package gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import lombok.NonNull;

public record AuthRequest(
        @NonNull @NotEmpty @Email
        String correo,
        @NonNull @NotEmpty
        String password
) {
}
