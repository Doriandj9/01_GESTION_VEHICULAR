package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosVehiculo;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record VehiculoRequestCreate(
        @NotNull @NotEmpty
        String placa,
        @NotNull @NotEmpty
        String conductor,
        @NotNull @Min(1)
        Long codParqueadero
) {

}
