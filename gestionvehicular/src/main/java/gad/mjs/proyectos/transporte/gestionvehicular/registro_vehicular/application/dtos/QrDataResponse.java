package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosQr;

public record QrDataResponse(
        Long codQr,
        String payload,
        EstadosQr estado,
        String qrBase64
) {
}
