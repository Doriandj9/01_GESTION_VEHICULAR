package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.contracts;

import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoRequestCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseRegistrado;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseReport;

import java.time.LocalDate;
import java.util.Date;
import java.util.List;

public interface IMovimientoService {

    MovimientoResponse registrar(MovimientoRequestCreate request);

    List<MovimientoResponseReport> listarUltimosMovimientos(int cantidad);

    List<MovimientoResponseReport> listarPorFechaInicioYFechaFin(LocalDate fechaInicio, LocalDate fechaFin);

    List<MovimientoResponseRegistrado> listarMovimientosDesdePorUsuario(Long codUsuario, LocalDate desde);
}
