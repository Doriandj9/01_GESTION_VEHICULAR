package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class DireccionParqueadero {
    private String callePrincipal;
    private String calleSecundaria;
    private BigDecimal latitud;
    private BigDecimal longitud;
    private String urlDireccion;

    public DireccionParqueadero(
            String callePrincipal,
            String calleSecundaria,
            BigDecimal latitud,
            BigDecimal longitud,
            String urlDireccion
    ) {

        if(callePrincipal == null || callePrincipal.isEmpty()){
            throw new DomainException("La calle principal de la direccion no puede ser vacia");
        }

        this.callePrincipal = callePrincipal;

        if(calleSecundaria != null && !calleSecundaria.isBlank()){
            this.calleSecundaria = calleSecundaria;
        }
        if(latitud != null){
            this.latitud = latitud;
        }

        if(longitud != null){
            this.longitud = longitud;
        }

        if(urlDireccion != null && !urlDireccion.isBlank()){
            this.urlDireccion = urlDireccion;
        }

    }
}
