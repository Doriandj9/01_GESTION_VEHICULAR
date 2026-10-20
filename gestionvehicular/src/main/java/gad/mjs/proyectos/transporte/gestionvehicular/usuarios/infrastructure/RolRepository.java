package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Rol;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.roles.Roles;
import org.jspecify.annotations.NullMarked;
import org.springframework.data.repository.CrudRepository;

import java.util.Optional;

@NullMarked
public interface RolRepository extends CrudRepository<Rol, Long> {

    boolean existsByRol(Roles rol);
    Optional<Rol> findByRol(Roles rol);
}
