package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.mappers;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.Vehiculo;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.infrastructure.VehiculoJpa;
import org.springframework.stereotype.Component;

@Component
public class VehiculoMapperDomain {

    public VehiculoJpa toJpa(Vehiculo entity) {
        return new VehiculoJpa(
                entity.getCodVehiculo(),
                entity.getPlaca().value(),
                entity.getConductor(),
                entity.getEstado(),
                entity.getCodParqueadero()
        );
    }

    public Vehiculo toDomain(VehiculoJpa entity) {
        Vehiculo vehiculo = new Vehiculo(
                entity.getCodParqueadero(),
                entity.getPlaca(),
                entity.getConductor(),
                entity.getEstado(),
                entity.getCodParqueadero()
        );

        return vehiculo;
    }
}
