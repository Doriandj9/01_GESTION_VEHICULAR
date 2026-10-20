package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.estados.EstadosParqueadero;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class Parqueadero {
    private Long codParqueadero;
    private String nombre;
    private DireccionParqueadero direccion;
    private EstadosParqueadero estado;

    public Parqueadero( Long codParqueadero,
                        String nombre,
                        String callePrincipal,
                        String calleSecundaria,
                        BigDecimal latitud,
                        BigDecimal longitud,
                        String urlDireccion,
                        EstadosParqueadero estado
                        ) {
        this.codParqueadero = codParqueadero;
        this.nombre = nombre.trim();
        this.direccion = new DireccionParqueadero(callePrincipal,calleSecundaria,latitud,longitud,urlDireccion);
        this.estado = estado;
    }

    public void desactivar(){
        this.estado = EstadosParqueadero.INACTIVO;
    }

    public void activar(){
        this.estado = EstadosParqueadero.ACTIVO;
    }

    public void actualizarDireccion(String callePrincipal,
                                                    String calleSecundaria,
                                                    BigDecimal latitud,
                                                    BigDecimal longitud,
                                                    String urlDireccion){

        if(estado.equals(EstadosParqueadero.INACTIVO)) {
            throw new DomainException("No se puede actualizar un parqueadero si se encuentra desactivado.");
        }
        if(callePrincipal == null){
            callePrincipal = this.direccion.getCallePrincipal();
        }
        this.direccion = new DireccionParqueadero(
                callePrincipal, calleSecundaria, latitud, longitud, urlDireccion);;
    }

    public void actualizarNombre(String nombre){
        if(estado.equals(EstadosParqueadero.INACTIVO)) {
            throw new DomainException("No se puede actualizar un parqueadero si se encuentra desactivado");
        }

        if(nombre == null || nombre.isBlank()){
            throw new DomainException("El nombre del parqueadero no puede ser nulo o vacio.");
        }

        this.nombre = nombre;
    }
}
