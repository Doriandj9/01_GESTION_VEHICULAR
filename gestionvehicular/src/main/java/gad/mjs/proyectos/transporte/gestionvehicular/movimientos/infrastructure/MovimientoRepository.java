package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.infrastructure;

import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseRegistrado;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseReport;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.Movimiento;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.Date;
import java.util.List;

public interface MovimientoRepository extends CrudRepository<Movimiento, Long> {


    @Query(
            value = """
            SELECT NEW gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseReport(
                        M.creadoPor,
                        U.nombres,
                        M.latitud,
                        M.longitud,
                        M.fechaHoraRegistro,
                        M.tipoMovimiento,
                        V.codVehiculo,
                        V.placa,
                        V.conductor,
                        P.codParqueadero,
                        P.nombre,
                        P.callePrincipal,
                        P.calleSecundaria,
                        P.latitud,
                        P.longitud,
                        P.urlDireccion
                        )
            FROM Movimiento M
                    JOIN VehiculoJpa V ON V.codVehiculo = M.codVehiculo
                    JOIN ParqueaderoJpa P ON M.codParqueadero = P.codParqueadero
                    JOIN Usuario U ON U.codUsuarios = M.creadoPor
                    ORDER BY M.fecha DESC
                    LIMIT :cantidad
            """
    )
    List<MovimientoResponseReport> findByLastMovimientos(@Param("cantidad") int cantidad);

    @Query(
            value = """
            SELECT NEW gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseReport(
                        M.creadoPor,
                        U.nombres,
                        M.latitud,
                        M.longitud,
                        M.fechaHoraRegistro,
                        M.tipoMovimiento,
                        V.codVehiculo,
                        V.placa,
                        V.conductor,
                        P.codParqueadero,
                        P.nombre,
                        P.callePrincipal,
                        P.calleSecundaria,
                        P.latitud,
                        P.longitud,
                        P.urlDireccion
                        )
            FROM Movimiento M
                    JOIN VehiculoJpa V ON V.codVehiculo = M.codVehiculo
                    JOIN ParqueaderoJpa P ON M.codParqueadero = P.codParqueadero
                    JOIN Usuario U ON U.codUsuarios = M.creadoPor
                    WHERE M.fecha BETWEEN :fechaInicio AND :fechaFin
                    ORDER BY M.fecha DESC
            """
    )
    List<MovimientoResponseReport> findByFechaInicioYFechaFin(@Param("fechaInicio") LocalDate fechaInicio,
                                                             @Param("fechaFin") LocalDate fechaFin);


    @Query(
            value = """
            SELECT NEW gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseRegistrado(
                        M.creadoPor,
                        U.nombres,
                        M.latitud,
                        M.longitud,
                        M.fechaHoraRegistro,
                        M.tipoMovimiento,
                        V.codVehiculo,
                        V.placa,
                        V.conductor
                        )
            FROM Movimiento M
                    JOIN VehiculoJpa V ON V.codVehiculo = M.codVehiculo
                    JOIN ParqueaderoJpa P ON M.codParqueadero = P.codParqueadero
                    JOIN Usuario U ON U.codUsuarios = M.creadoPor
                    WHERE M.fecha >= :fecha
                    AND U.codUsuarios = :codUsuario
                    ORDER BY M.fecha DESC
            """
    )
    List<MovimientoResponseRegistrado> findByFechaDesde(@Param("codUsuario") Long codUsuario, @Param("fecha") LocalDate fecha);

}
