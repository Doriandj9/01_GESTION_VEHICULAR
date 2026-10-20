package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.infrastructure.ParqueaderoJpa;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.infrastructure.ParqueaderoRepository;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts.IQrService;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts.IVehiculoService;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.*;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.mappers.VehiculoMapperApplication;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.Vehiculo;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosVehiculo;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.mappers.VehiculoMapperDomain;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.infrastructure.VehiculoJpa;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.infrastructure.VehiculoRepository;
import jakarta.servlet.Servlet;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.StreamSupport;


@Service
@RequiredArgsConstructor
public class VehiculoService implements IVehiculoService {
    private final ParqueaderoRepository parqueaderoRepository;
    private final VehiculoRepository vehiculoRepository;
    private final VehiculoMapperDomain vehiculoMapperDomain;
    private final VehiculoMapperApplication  vehiculoMapperApplication;
    private final IQrService qrService;
    private final Servlet servlet;

    @Transactional
    @Override
    public VehiculoResponseCreate registrar(VehiculoRequestCreate request) {

        ParqueaderoJpa parqueaderoJpa = parqueaderoRepository.findById(request.codParqueadero())
                .orElseThrow( () -> new DomainException("No existe el parquedero que se requiere activar al vehiculo"));


        Vehiculo vehiculo = new Vehiculo(
                null,
                request.placa(),
                request.conductor(),
                EstadosVehiculo.ACTIVO,
                parqueaderoJpa.getCodParqueadero()
        );

        VehiculoJpa result = vehiculoRepository.save(vehiculoMapperDomain.toJpa(vehiculo));

        Map<String, Object> claims = new LinkedHashMap<>();
        claims.put("ident", result.getCodVehiculo());
        claims.put("conductor", request.conductor());
        claims.put("fecha_creacion", System.currentTimeMillis());

        PayloadQrData payloadQrData = new PayloadQrData(result.getCodVehiculo().toString(),result.getPlaca(),claims);

        QrDataResponse qr = qrService.registrarQrPorVehiculo(result.getCodVehiculo(), payloadQrData);

        return vehiculoMapperApplication.toResponse(
                vehiculoMapperDomain.toDomain(result),
                qr.qrBase64()
        );
    }

    @Override
    public List<VehiculoResponseCreate> listarVehiculos() {
        return StreamSupport.stream(vehiculoRepository.findAll().spliterator(), false)
                .map(vehiculoMapperDomain::toDomain)
                .map(v -> vehiculoMapperApplication.toResponse(v,null))
                .toList();
    }

    @Override
    public VehiculoResponseCreate actualizar(Long codVehiculo,VehiculoRequestUpdate request) {
        VehiculoJpa vehiculoJpa = vehiculoRepository.findByCodVehiculo(codVehiculo)
                .orElseThrow(() -> new DomainException("No existe el vehiculo para actualizar"));

        ParqueaderoJpa parqueaderoJpa = null;

        if(request.codParqueadero() != null &&
                !vehiculoJpa.getCodParqueadero().equals(request.codParqueadero())) {
            parqueaderoJpa = parqueaderoRepository.findByCodParqueadero(request.codParqueadero())
                    .orElseThrow(() -> new DomainException("No existe el parqueadero para actualizar"));
        }

        Vehiculo vehiculo = vehiculoMapperDomain.toDomain(vehiculoJpa);

        vehiculo = vehiculoMapperApplication.toUpdate(vehiculo,request);

        vehiculoJpa = vehiculoMapperDomain.toJpa(vehiculo);

        Map<String, Object> claims = new LinkedHashMap<>();
        claims.put("ident", vehiculo.getCodVehiculo());
        claims.put("conductor", request.conductor());
        claims.put("fecha_creacion", System.currentTimeMillis());

        PayloadQrData payload = new PayloadQrData(
                vehiculo.getCodVehiculo().toString(),
                vehiculo.getPlaca().value(),
                claims
        );

        QrDataResponse qr = qrService.registrarQrPorVehiculo(vehiculoJpa.getCodVehiculo(),payload);
        return vehiculoMapperApplication.toResponse(vehiculo, qr.qrBase64());
    }

    @Override
    public VehiculoResponseCreate obtenerVehiculo(Long codVehiculo) {
            VehiculoJpa vehiculoJpa = vehiculoRepository.findByCodVehiculo(codVehiculo)
                .orElseThrow(() -> new DomainException("No existe el vehiculo"));

        Vehiculo vehiculo =  vehiculoMapperDomain.toDomain(vehiculoJpa);
        var res = qrService.obtenerQrActivoPorVehiculo(vehiculoJpa.getCodVehiculo());
        return vehiculoMapperApplication.toResponse(vehiculo,res.qrBase64());

    }
}
