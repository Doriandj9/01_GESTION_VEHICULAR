package gad.mjs.proyectos.transporte.gestionvehicular.configuraciones;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@Configuration
@EnableJpaAuditing(auditorAwareRef = "auditorAware")
public class JpaAuditoriaConfig {
}
