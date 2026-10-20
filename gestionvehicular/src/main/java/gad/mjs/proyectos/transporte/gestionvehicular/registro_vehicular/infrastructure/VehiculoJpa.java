package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.infrastructure;

import gad.mjs.proyectos.transporte.gestionvehicular.common.audit.Auditable;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosVehiculo;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "vehiculos")
public class VehiculoJpa extends Auditable {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long codVehiculo;
    @Column(nullable = false,  unique = true)
    private String placa;
    private String conductor;
    private EstadosVehiculo estado;
    @Column(nullable = false)
    private Long codParqueadero;


    public VehiculoJpa(String placa , String conductor, EstadosVehiculo estado, Long codParqueadero){
        this(null, placa, conductor, estado, codParqueadero);
    }
}
