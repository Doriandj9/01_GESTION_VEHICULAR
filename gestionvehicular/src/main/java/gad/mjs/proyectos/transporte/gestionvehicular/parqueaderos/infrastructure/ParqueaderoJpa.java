package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.infrastructure;

import gad.mjs.proyectos.transporte.gestionvehicular.common.audit.Auditable;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.estados.EstadosParqueadero;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "parqueaderos")
public class ParqueaderoJpa extends Auditable {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long codParqueadero;
    private String nombre;
    private String callePrincipal;
    private String calleSecundaria;
    private BigDecimal latitud;
    private BigDecimal longitud;
    private String urlDireccion;
    private EstadosParqueadero estado;
}
