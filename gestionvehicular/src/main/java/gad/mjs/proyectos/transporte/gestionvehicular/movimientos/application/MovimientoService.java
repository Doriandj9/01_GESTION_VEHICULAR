package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.contracts.IMovimientoService;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoRequestCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseRegistrado;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseReport;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.mappers.MovimientoApplicationMapper;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.Movimiento;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.estados.EstadosMovimientos;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.infrastructure.MovimientoRepository;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts.IQrGenerator;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts.IVehiculoService;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Date;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MovimientoService implements IMovimientoService {
    private final IQrGenerator  qrGenerator;
    private final IVehiculoService vehiculoService;
    private final MovimientoRepository repository;
    private final MovimientoApplicationMapper mapperApplication;

    @Override
    public MovimientoResponse registrar(MovimientoRequestCreate request) {
        if(!qrGenerator.validateQr(request.data())){
            throw new DomainException("Error el qr escaneado no es valido para registrar");
        }
        String id = qrGenerator.extractClaim(request.data(), Claims::getId);

        var vehiculo = vehiculoService.obtenerVehiculo(Long.parseLong(id));

        Movimiento movimiento = new Movimiento(
                null,
                vehiculo.codVehiculo(),
                vehiculo.codParqueadero(),
                LocalDate.now(),
                Instant.now(),
                request.tipo(),
                request.latitud(),
                request.longitud()
        );

        repository.save(movimiento);

        return  mapperApplication.toResponse(movimiento, EstadosMovimientos.SUCCESS);
    }

    @Override
    public List<MovimientoResponseReport> listarUltimosMovimientos(int cantidad) {
        return repository.findByLastMovimientos(cantidad);
    }


    @Override
    public List<MovimientoResponseReport> listarPorFechaInicioYFechaFin(LocalDate fechaInicio, LocalDate fechaFin) {
        return repository.findByFechaInicioYFechaFin(fechaInicio, fechaFin);
    }

    @Override
    public List<MovimientoResponseRegistrado> listarMovimientosDesdePorUsuario(Long codUsuario, LocalDate desde) {
        return repository.findByFechaDesde(codUsuario, desde);
    }


}
