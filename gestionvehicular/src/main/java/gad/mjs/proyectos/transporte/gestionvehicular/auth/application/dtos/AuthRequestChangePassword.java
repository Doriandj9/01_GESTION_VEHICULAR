package gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record AuthRequestChangePassword(
        @NotNull @NotEmpty @Email
        String correo,
        @NotNull @NotEmpty
        String oldPassword,
        @NotNull @NotEmpty
        String newPassword
) {
}
