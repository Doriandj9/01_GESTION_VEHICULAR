package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.mappers;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos.UsuarioResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.estados.EstadosUsuario;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
@RequiredArgsConstructor
public class UserMapper {
    private final PasswordEncoder passwordEncoder;


    public UsuarioResponse toResponse(Usuario usuario){
        return  new UsuarioResponse(
                usuario.getCodUsuarios(),
                usuario.getNombres(),
                usuario.getCorreo(),
                usuario.getEstado(),
                usuario.getRol().getRol()
        );
    }

    public Usuario toUpdateUsuario(Usuario usuario, Map<String, Object> campos){

        if(campos.containsKey("nombres") && campos.get("nombres") != null){
            usuario.setNombres((String) campos.get("nombres"));
        }
        if(campos.containsKey("correo") && campos.get("correo") != null){
            usuario.setCorreo((String) campos.get("correo"));
        }

        if (campos.containsKey("password") && campos.get("password") != null){
            var password = passwordEncoder.encode((String) campos.get("password"));
            usuario.setPassword(password);
        }

        if(campos.containsKey("estado")  && campos.get("estado") != null){
            var estado = EstadosUsuario.valueOf(String.valueOf(campos.get("estado")));
            if(estado.equals(EstadosUsuario.ACTIVO) && usuario.getEstado().equals(EstadosUsuario.INICIAL)){
                throw  new DomainException("No se puede activar un usuario en estado inicial por que debe cambiar la contraseña por defecto.");
            }
            usuario.setEstado(estado);
        }

        return usuario;
    }
}
