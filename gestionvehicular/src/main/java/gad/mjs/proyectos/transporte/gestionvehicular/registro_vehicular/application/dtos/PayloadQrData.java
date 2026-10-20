package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.common.serializes.JsonSerialize;

import java.util.Map;

public record PayloadQrData(
        String identifier,
        String subject,
        Map<String, Object> claims
) implements JsonSerialize {
}
