package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.common.audit.Auditable;
import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.domain.tipo.TiposMovimiento;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Date;

@Entity
@NoArgsConstructor
@Getter
public class Movimiento extends Auditable {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long codMovimiento;
    private Long codVehiculo;
    private Long codParqueadero;
    private LocalDate fecha;
    private Instant fechaHoraRegistro;
    private TiposMovimiento  tipoMovimiento;
    private BigDecimal latitud;
    private BigDecimal longitud;

    public  Movimiento(
            Long codMovimiento,
            Long codVehiculo,
            Long codParqueadero,
            LocalDate fecha,
            Instant fechaHoraRegistro,
            TiposMovimiento tipoMovimiento,
            BigDecimal latitud,
            BigDecimal longitud
    ) {

        if(codVehiculo==null || codParqueadero == null || fecha == null || fechaHoraRegistro == null || tipoMovimiento==null || latitud==null || longitud==null ){
            throw new DomainException("No se encuentran los datos completos revise [vehiculo, parquedero, fecha registro, tipo de registro]");
        }
        this.codMovimiento = codMovimiento;
        this.codVehiculo = codVehiculo;
        this.codParqueadero = codParqueadero;
        this.fecha = fecha;
        this.fechaHoraRegistro = fechaHoraRegistro;
        this.tipoMovimiento = tipoMovimiento;
        this.latitud = latitud;
        this.longitud = longitud;
    }
}
