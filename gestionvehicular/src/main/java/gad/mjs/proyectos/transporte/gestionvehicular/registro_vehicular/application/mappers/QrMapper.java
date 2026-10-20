package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.mappers;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.QrDataResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.Qr;
import org.springframework.stereotype.Component;

@Component
public class QrMapper {

    public QrDataResponse tooQrDataResponseNotQr64(Qr qr) {
        return new QrDataResponse(
                qr.getCodQr(),
                qr.getPayload(),
                qr.getEstado(),
                null
        );
    }
}
