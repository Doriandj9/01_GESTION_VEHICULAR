package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.mappers;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.VehiculoRequestUpdate;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.VehiculoResponseCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.Vehiculo;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosVehiculo;
import org.springframework.stereotype.Component;

@Component
public class VehiculoMapperApplication {


    public VehiculoResponseCreate toResponse(Vehiculo vehiculo, String qrCodeBase64) {
        return new VehiculoResponseCreate(
                vehiculo.getCodVehiculo(),
                vehiculo.getPlaca().value(),
                vehiculo.getConductor(),
                vehiculo.getEstado(),
                vehiculo.getCodParqueadero(),
                qrCodeBase64
        );
    }

    public Vehiculo toUpdate(Vehiculo vehiculo, VehiculoRequestUpdate campos) {

        if(campos.placa() != null && !campos.placa().isEmpty()){
            vehiculo.actualizarPlaca(campos.placa());
        }

        if(campos.conductor() != null && !campos.conductor().isEmpty()){
            vehiculo.actualizarConductor(campos.conductor());
        }

        if(campos.estado() != null){
            if (campos.estado().equals(EstadosVehiculo.ACTIVO)) {
                vehiculo.activar();
            } else {
                vehiculo.desactivar();
            }
        }

        if(campos.codParqueadero() != null){
            vehiculo.actualizarParqueadero(campos.codParqueadero());
        }

        return vehiculo;
    }
}
