package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.common.audit.Auditable;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.domain.estados.EstadosQr;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Entity
@AllArgsConstructor
@NoArgsConstructor
public class Qr extends Auditable {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long codQr;
    private String payload;
    private EstadosQr estado;
    private Long codVehiculo;


    public Qr(String payload, EstadosQr estado, Long codVehiculo){
        this(null, payload, estado, codVehiculo);
    }

}
