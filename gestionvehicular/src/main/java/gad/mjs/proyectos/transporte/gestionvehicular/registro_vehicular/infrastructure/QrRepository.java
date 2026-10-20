package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.infrastructure;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.Qr;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosQr;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface QrRepository extends CrudRepository<Qr,Long> {

    Optional<Qr> findByCodQr(Long codQr);

    List<Qr> findByCodVehiculo(Long codVehiculo);

    Optional<Qr> findByCodVehiculoAndEstado(Long codVehiculo, EstadosQr estado);
}
