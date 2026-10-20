package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain;

import org.hibernate.Hibernate;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class UserDetailsMapper {

    public UserDetails toUserDetails(Usuario usuario) {
        String rol = usuario.getRol().getRol().name();
        return org.springframework.security.core.userdetails.User
                .withUsername(usuario.getCorreo())
                .password("")
                .authorities(
                        List.of("ROLE_" + rol)
                                .toArray(String[]::new)
                )
                .build();
    }
}
