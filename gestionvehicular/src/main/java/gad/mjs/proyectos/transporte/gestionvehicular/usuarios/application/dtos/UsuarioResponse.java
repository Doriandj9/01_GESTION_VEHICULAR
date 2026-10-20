package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.estados.EstadosUsuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.roles.Roles;

public record UsuarioResponse(
        Long codUsuario,
        String nombres,
        String correo,
        EstadosUsuario estado,
        Roles rol
) {
}
