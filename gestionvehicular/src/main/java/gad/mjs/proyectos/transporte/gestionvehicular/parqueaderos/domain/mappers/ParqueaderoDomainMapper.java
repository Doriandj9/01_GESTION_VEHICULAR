package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.mappers;

import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.Parqueadero;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.infrastructure.ParqueaderoJpa;
import org.springframework.stereotype.Component;

@Component
public class ParqueaderoDomainMapper {

    public ParqueaderoJpa toJpa(Parqueadero parqueadero) {

        return new ParqueaderoJpa(
                parqueadero.getCodParqueadero(),
                parqueadero.getNombre(),
                parqueadero.getDireccion().getCallePrincipal(),
                parqueadero.getDireccion().getCalleSecundaria(),
                parqueadero.getDireccion().getLatitud(),
                parqueadero.getDireccion().getLongitud(),
                parqueadero.getDireccion().getUrlDireccion(),
                parqueadero.getEstado()
        );
    }

    public Parqueadero toDomain(ParqueaderoJpa parqueadero) {

        return new Parqueadero(
                parqueadero.getCodParqueadero(),
                parqueadero.getNombre(),
                parqueadero.getCallePrincipal(),
                parqueadero.getCalleSecundaria(),
                parqueadero.getLatitud(),
                parqueadero.getLongitud(),
                parqueadero.getUrlDireccion(),
                parqueadero.getEstado()
        );
    }
}
