package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;

public record PlacaVehiculo(String value) {

    public  PlacaVehiculo{
        if(value==null || value.isEmpty())
            throw new DomainException("La placa no puede estar vacia");

        value=value.toUpperCase();
    }
}
