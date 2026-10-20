package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record UsuarioRequestCreate(
        @NotBlank
        String nombre,
        @NotBlank @Email
        String correo,
        @NotBlank
        String rol
) {
}
