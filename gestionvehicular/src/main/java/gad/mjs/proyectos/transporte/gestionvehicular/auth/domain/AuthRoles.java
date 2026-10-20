package gad.mjs.proyectos.transporte.gestionvehicular.auth.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;

public class AuthRoles {

    private String role;

    public  AuthRoles(Usuario usuario)
    {

        if (usuario==null){
            throw new DomainException("No se asigno un usuario para generar sus roles");
        }

        if(usuario.getRol() == null)
        {
            throw new DomainException("No se asigno un rol de usuario");
        }

        this.role = usuario.getRol().getRol().toString();
    }

    public String getRole() {
        return role;
    }

}
