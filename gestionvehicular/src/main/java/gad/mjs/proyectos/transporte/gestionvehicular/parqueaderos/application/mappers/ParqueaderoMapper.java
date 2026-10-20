package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.application.mappers;

import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.Parqueadero;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.estados.EstadosParqueadero;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderResponseCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderoRequestUpdate;
import org.springframework.stereotype.Component;


@Component
public class ParqueaderoMapper {

    public ParqueaderResponseCreate toResponse(Parqueadero parqueadero){
        return new ParqueaderResponseCreate(
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

    public Parqueadero toUpdateParqueadero(Parqueadero parqueadero, ParqueaderoRequestUpdate request) {

        if(request.nombre() != null && !request.nombre().isBlank()){
            parqueadero.actualizarNombre(request.nombre());
        }

        if(request.callePrincipal() != null ||  request.calleSecundaria() != null || request.latitud() != null || request.longitud() != null || request.urlDireccion() != null){
            parqueadero.actualizarDireccion(request.callePrincipal(),request.calleSecundaria(),request.latitud(),request.longitud(),request.urlDireccion());
        }

        if(request.estado() != null){
            if(request.estado().equals(EstadosParqueadero.ACTIVO)){
                parqueadero.activar();
            }
            if(request.estado().equals(EstadosParqueadero.INACTIVO)){
                parqueadero.desactivar();
            }
        }

        return parqueadero;
    }
}
