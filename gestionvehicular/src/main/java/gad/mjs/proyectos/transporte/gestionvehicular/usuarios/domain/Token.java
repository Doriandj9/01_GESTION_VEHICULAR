package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.tokens.TokenType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "tokens")
public class Token {

    @Id
    @GeneratedValue
    private Long tokenId;

    @Column(columnDefinition = "TEXT")
    private String token;

    @Enumerated(EnumType.STRING)
    private TokenType tokenType = TokenType.BEARER;

    private boolean expired = false;

    private boolean revoke = false;

    @EqualsAndHashCode.Exclude
    private Instant createdAt;

    @EqualsAndHashCode.Exclude
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cod_usuarios")
    private Usuario usuario;


    public Token(String token, Usuario usuario) {
        this(null,token,TokenType.BEARER,false,false,Instant.now(),usuario);
    }

    public Token(String token, boolean expired, boolean revoke, Usuario usuario) {
        this(null,token,TokenType.BEARER,false,false,Instant.now(),usuario);
    }
}
