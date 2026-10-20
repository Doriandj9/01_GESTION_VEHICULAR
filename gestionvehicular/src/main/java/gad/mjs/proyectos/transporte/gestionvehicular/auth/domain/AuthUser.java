package gad.mjs.proyectos.transporte.gestionvehicular.auth.domain;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.tokens.TokenType;
import lombok.Getter;

import java.util.Map;
import java.util.Set;

public class AuthUser {
    @Getter
    private boolean isLogin;
    @Getter
    private Map<String,Object> claimsAccessToken;
    @Getter
    private Map<String, Object> claimsRefreshToken;
    private final Usuario usuario;
    @Getter
    private final AuthRoles authRoles;

    public AuthUser(Usuario usuario) {
        this.usuario = usuario;
        this.authRoles = new AuthRoles(usuario);
        isLogin = true;
    }

    public void generateClaims(){
        this.claimsAccessToken = Map.of(
                "type", TokenType.ACCESS_TOKEN.name(),
                "ident", usuario.getCodUsuarios(),
                "roles", Set.of(authRoles.getRole())
        );

                //Set.of("ACCESS_TOKEN", "USER_ID:" + usuario.getCodUsuarios(), "AUTHENTICATED_BY_ROL_" + authRoles.getRole());
        this.claimsRefreshToken = Map.of(
                "type", TokenType.REFRESH_TOKEN.name(),
                "ident", usuario.getCodUsuarios(),
                "roles", Set.of()
        );
    }
}
