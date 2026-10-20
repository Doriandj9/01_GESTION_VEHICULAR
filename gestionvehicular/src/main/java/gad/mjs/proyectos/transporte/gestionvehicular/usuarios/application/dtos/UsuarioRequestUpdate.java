package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.estados.EstadosUsuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.roles.Roles;

public record UsuarioRequestUpdate(
        String nombres,
        String correo,
        String password,
        Roles rol,
        EstadosUsuario estado
) {
}
