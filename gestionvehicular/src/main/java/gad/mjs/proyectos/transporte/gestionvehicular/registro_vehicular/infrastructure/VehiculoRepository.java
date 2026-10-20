package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.infrastructure;

import org.springframework.data.repository.CrudRepository;

import java.util.Optional;

public interface VehiculoRepository extends CrudRepository<VehiculoJpa, Long> {

    Optional<VehiculoJpa> findByCodVehiculo(Long codVehiculo);

    Optional<VehiculoJpa> findByPlaca(String nombre);


}
