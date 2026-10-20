package gad.mjs.proyectos.transporte.gestionvehicular.common.audit;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jspecify.annotations.NullMarked;
import org.springframework.data.domain.AuditorAware;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import java.util.Optional;

@Slf4j
@NullMarked
@Component("auditorAware")
@RequiredArgsConstructor
public class SecurityAuditorAware implements AuditorAware<Long> {
    private final UsuarioRepository usuarioRepository;

    @Override
    public Optional<Long> getCurrentAuditor() {
        Authentication authentication =
                SecurityContextHolder
                        .getContext()
                        .getAuthentication();

        if (authentication == null ||
                !authentication.isAuthenticated()) {

            return Optional.empty();
        }

        if (authentication.getPrincipal() instanceof Usuario usuario) {
            return Optional.of(usuario.getCodUsuarios());
        }

        return usuarioRepository.findIdByCorreo(authentication.getName());
    }
}