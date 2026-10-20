package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosVehiculo;

public record VehiculoResponseCreate(
        Long codVehiculo,
        String placa,
        String conductor,
        EstadosVehiculo estado,
        Long codParqueadero,
        String qrCodeBase64
) {
}
