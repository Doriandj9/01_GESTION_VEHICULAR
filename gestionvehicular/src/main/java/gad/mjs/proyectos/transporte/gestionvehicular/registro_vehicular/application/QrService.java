package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts.IQrGenerator;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts.IQrService;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.PayloadQrData;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.QrDataResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.mappers.QrMapper;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.Qr;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosQr;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.infrastructure.QrRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class QrService  implements IQrService {
    private final IQrGenerator  qrGenerator;
    private final QrRepository  qrRepository;
    private final QrMapper qrMapper;

    @Override
    public QrDataResponse registrarQrPorVehiculo(Long codVehiculo, PayloadQrData payloadQrData) {
        Qr qr = new Qr(payloadQrData.toJson(),EstadosQr.ACTIVO,codVehiculo);
        qrRepository.save(qr);
        String b64Qr = qrGenerator.toBase64(qrGenerator.generateQr(payloadQrData));

        return new QrDataResponse(qr.getCodQr(),qr.getPayload(),qr.getEstado(),b64Qr);
    }

    @Override
    public List<QrDataResponse> listarQrPorVehiculo(Long codVehiculo) {
        return qrRepository.findByCodVehiculo(codVehiculo).stream().map(qrMapper::tooQrDataResponseNotQr64).toList();
    }

    @Override
    public QrDataResponse actualizarEstado(Long codQr, EstadosQr estado) {
        Qr qr = qrRepository.findByCodQr(codQr).orElseThrow(() -> new DomainException("No existe qr"));

        qr.setEstado(estado);

        qrRepository.save(qr);

        return qrMapper.tooQrDataResponseNotQr64(qr);
    }

    @Override
    public QrDataResponse obtenerQrActivoPorVehiculo(Long codVehiculo) {
        Optional<Qr> qrActivo = qrRepository.findByCodVehiculoAndEstado(codVehiculo, EstadosQr.ACTIVO);

        if(qrActivo.isEmpty()){
            return null;
        }

        Qr qr = qrActivo.get();

        ObjectMapper mapper = new ObjectMapper();

        PayloadQrData payload = mapper.readValue(qr.getPayload(), PayloadQrData.class);

        String qrBase64 = qrGenerator.toBase64(qrGenerator.generateQr(payload));

        return new QrDataResponse(qr.getCodQr(),qr.getPayload(),qr.getEstado(),qrBase64);
    }
}
