package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.infrastructure;

import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.Parqueadero;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface ParqueaderoRepository extends CrudRepository<ParqueaderoJpa, Long> {

    boolean existsByNombreIgnoreCase(String nombre);

    Optional<ParqueaderoJpa> findByNombreIgnoreCase(String nombre);

    Optional<ParqueaderoJpa> findByCodParqueadero(Long codParqueadero);

    List<ParqueaderoJpa> findAllByOrderByFechaCreacionDesc();
}
