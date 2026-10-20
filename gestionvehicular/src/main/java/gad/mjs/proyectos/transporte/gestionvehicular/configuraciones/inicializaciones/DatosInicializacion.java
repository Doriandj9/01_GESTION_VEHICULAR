package gad.mjs.proyectos.transporte.gestionvehicular.configuraciones.inicializaciones;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Rol;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.estados.EstadosUsuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.roles.Roles;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure.RolRepository;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
@Slf4j
public class DatosInicializacion {

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final PasswordEncoder passwordEncoder;

    @Bean
    CommandLineRunner initUsuario(){
        return args -> {

            try{
                if(!rolRepository.existsByRol(Roles.ADMINISTRADOR)){
                    rolRepository.save(new Rol(Roles.ADMINISTRADOR));
                    log.info("Rol {} inicializado correctamente", Roles.ADMINISTRADOR.name());
                }

                if(!rolRepository.existsByRol(Roles.GUARDIA)){
                    rolRepository.save(new Rol(Roles.GUARDIA));
                    log.info("Rol {} inicializado correctamente", Roles.ADMINISTRADOR.name());
                }

                if(rolRepository.existsByRol(Roles.ADMINISTRADOR)){
                    if(!usuarioRepository.existsByCorreo("admin@gadmjs.com")){
                        Rol rol = rolRepository.findByRol(Roles.ADMINISTRADOR).orElse(null);

                        String password = passwordEncoder.encode("12345");

                        Usuario usuario = new Usuario("ADMIN","admin@gadmjs.com",password, EstadosUsuario.INICIAL, rol);

                        usuarioRepository.save(usuario);

                        log.info("Usuario {} inicializado correctamente", usuario.getCorreo());
                    }
                } else {
                    log.error("No se existe el rol {} para registrar en el usuario admin", Roles.ADMINISTRADOR.name());
                }


            }catch(Exception ex){
                log.error("Error al inicializar los roles: {}",ex.getMessage(),ex);
            }
        };
    }

}
