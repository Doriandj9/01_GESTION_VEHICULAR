package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.PayloadQrData;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.QrDataCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.QrDataResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.Qr;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.Vehiculo;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosQr;

import java.util.List;

public interface IQrService {
    QrDataResponse registrarQrPorVehiculo(Long codVehiculo, PayloadQrData payloadQrData);

    List<QrDataResponse> listarQrPorVehiculo(Long codVehiculo);

    QrDataResponse actualizarEstado(Long codQr, EstadosQr estado);

    QrDataResponse obtenerQrActivoPorVehiculo(Long codVehiculo);
}
