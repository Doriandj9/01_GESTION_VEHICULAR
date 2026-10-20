package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.roles.Roles;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "roles")
public class Rol {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long codRol;
    @Enumerated(EnumType.STRING)
    private Roles rol;


    public Rol(Roles rol){
        this(null,rol);
    }
}
