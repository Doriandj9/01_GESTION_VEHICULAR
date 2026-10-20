package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import gad.mjs.proyectos.transporte.gestionvehicular.common.audit.Auditable;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.estados.EstadosUsuario;
import jakarta.persistence.*;
import lombok.*;

import java.io.Serializable;

@Entity
@Getter @Setter
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "usuarios")
@JsonIgnoreProperties({"hibernateLazyInitializer","handler"})
public class Usuario extends Auditable implements Serializable {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long codUsuarios;
    private String nombres;
    @Column(nullable = false, unique = true)
    private String correo;
    private String password;
    private EstadosUsuario  estado;

    @JoinColumn(name = "cod_rol")
    @ManyToOne(fetch = FetchType.LAZY)
    private Rol rol;

    public Usuario(String nombres, String correo, String password, EstadosUsuario estado, Rol rol) {
        this(null, nombres, correo, password, estado, rol);
    }


    public void desactivar(){
        this.estado = EstadosUsuario.INACTIVO;
    }

    public void activar(){
        this.estado = EstadosUsuario.ACTIVO;
    }
}
