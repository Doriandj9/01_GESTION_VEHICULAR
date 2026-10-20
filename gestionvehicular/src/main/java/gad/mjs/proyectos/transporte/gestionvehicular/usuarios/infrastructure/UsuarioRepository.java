package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import jakarta.persistence.QueryHint;
import org.jspecify.annotations.NullMarked;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.QueryHints;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

@NullMarked
public interface UsuarioRepository extends CrudRepository<Usuario, Long> {

    Optional<Usuario> findByCorreo(String correo);

    boolean existsByCorreo(String correo);

    @QueryHints(@QueryHint(name = "org.hibernate.flushMode", value = "COMMIT"))
    @Query("select u.codUsuarios from Usuario u where u.correo = :correo")
    Optional<Long> findIdByCorreo(@Param("correo") String correo);
}
