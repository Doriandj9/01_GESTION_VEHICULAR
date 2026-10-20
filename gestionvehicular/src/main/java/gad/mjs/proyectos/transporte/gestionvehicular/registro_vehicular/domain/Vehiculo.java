package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosVehiculo;
import lombok.*;

@Getter
public class Vehiculo  {
    private Long codVehiculo;
    private PlacaVehiculo placa;
    private String conductor;
    private EstadosVehiculo estado;
    private Long codParqueadero;
    private Long codQrData;

    public Vehiculo(
            Long codVehiculo,
            String placa,
            String conductor,
            EstadosVehiculo estado,
            Long codParqueadero
    ){
        this.codVehiculo = codVehiculo;
        this.placa = new PlacaVehiculo(placa);
        this.conductor = conductor;
        this.estado = estado;
        this.codParqueadero = codParqueadero;
    }


    public void desactivar(){
        this.estado =  EstadosVehiculo.INACTIVO;
    }

    public void activar(){
        this.estado =  EstadosVehiculo.ACTIVO;
    }

    public void actualizarPlaca(String placa){
        this.verificarQueEstaActivo();
        this.placa = new PlacaVehiculo(placa);
    }

    public void actualizarConductor(String conductor){
        this.verificarQueEstaActivo();
        if(conductor == null || conductor.isBlank()){
            throw new DomainException("Conductor no puede ser nulo o vacio");
        }

        this.conductor = conductor;
    }

    public void actualizarParqueadero(Long codParqueadero){
        this.verificarQueEstaActivo();
        if(codParqueadero == null){
            throw new DomainException("El parqueadero es obligatorio");
        }

        this.codParqueadero = codParqueadero;
    }

    public void actualizarQrData(Long codQrData){
        this.verificarQueEstaActivo();
        if(codQrData == null){
            throw new DomainException("La qr no puede ser nula");
        }
        this.codQrData = codQrData;
    }

    private void verificarQueEstaActivo(){
        if(estado.equals(EstadosVehiculo.INACTIVO)){
            throw new DomainException("No se puede actualizar el Vehiculo si encuentra inactivo");
        }

    }

}
