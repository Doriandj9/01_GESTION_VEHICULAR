package gad.mjs.proyectos.transporte.gestionvehicular.auth.application;

import gad.mjs.proyectos.transporte.gestionvehicular.auth.application.contacts.IAuthService;
import gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos.AuthResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos.LogoutResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.auth.domain.AuthUser;
import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.seguridades.JwtService;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Token;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.estados.EstadosUsuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure.TokenRepository;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.InvalidParameterException;
import java.util.HashMap;
import java.util.Map;


@Service
@Slf4j
@RequiredArgsConstructor
public class AuthService implements IAuthService {
    private final AuthenticationManager authenticationManager;
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final TokenRepository tokenRepository;
    @Value("${application.security.jwt.expiration}")
    private Long jwtExpired;

    @Transactional
    @Override
    public AuthResponse login(String correo, String password) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            correo,
                            password
                    )
            );
        }catch (AuthenticationException e) {
            throw new BadCredentialsException("Invalid username/password");
        }

        Usuario usuario = usuarioRepository.findByCorreo(correo)
                .orElseThrow(() -> new InvalidParameterException("No se encuentra el usuario"));

        return getAuthResponse(usuario);
    }

    @Transactional
    @Override
    public AuthResponse refresh(String token) {
        Token tokenEntity = tokenRepository.findByToken(token).orElseThrow(() -> new DomainException("Token no encontrado."));
        if(tokenEntity.isExpired() || tokenEntity.isRevoke()){
            throw new DomainException("Token invalido vuelva iniciar sesion.");
        }
        String correo = jwtService.extractUsername(token);
        Usuario usuario = usuarioRepository.findByCorreo(correo).orElseThrow(() -> new DomainException("Usuario no encontrado."));

        return getAuthResponse(usuario);
    }

    private AuthResponse getAuthResponse(Usuario usuario) {
        Map<String, String> values = getTokens(usuario);

        String jwt = values.get("jwt");
        String refreshToken = values.get("refreshToken");
        Long timeExpired = Long.parseLong(values.get("jwtExpired"));

        return new AuthResponse(jwt, refreshToken, timeExpired);
    }

    @Override
    public LogoutResponse logout(String token) {
        String d = "n";
        return null;
    }

    @Transactional
    @Override
    public AuthResponse changePassword(String correo, String oldPassword, String newPassword) {
        Usuario usuario = usuarioRepository.findByCorreo(correo).orElseThrow(() -> new DomainException("Usuario no encontrado"));
        if(!passwordEncoder.matches(oldPassword, usuario.getPassword())){
            throw new BadCredentialsException("La contraseña es incorrecta");
        }

        usuario.setPassword(passwordEncoder.encode(newPassword));
        usuario.setEstado(EstadosUsuario.ACTIVO);
        usuarioRepository.save(usuario);

        return getAuthResponse(usuario);
    }

    private void saveTokenUser(Usuario usuario, String token) {
        tokenRepository.save(new Token(token, usuario));
    }

    public void revokedAllTokens(Usuario usuario) {
       int rowsAffects = tokenRepository.updateRevokedAllByUser(usuario.getCodUsuarios(),true);

       log.debug("Filas afectadas de tokens rowsAffects: {}", rowsAffects);
    }

    private Map<String, String> getTokens(Usuario usuario) {

        AuthUser authUser = new AuthUser(usuario);
        authUser.generateClaims();

        Long startTime = System.currentTimeMillis();

        String jwt = jwtService.generateToken(usuario,  authUser.getClaimsAccessToken());
        String refreshToken = jwtService.generateRefreshToken(usuario, authUser.getClaimsRefreshToken());

        revokedAllTokens(usuario);
        saveTokenUser(usuario,refreshToken);

        Long endTime = System.currentTimeMillis();

        Long duration = endTime - startTime;

        long timeExpired = jwtExpired - duration ;

        Map<String, String> tokens = new HashMap<>();
        tokens.put("jwt", jwt);
        tokens.put("refreshToken", refreshToken);
        tokens.put("jwtExpired", String.valueOf(timeExpired));

        return tokens;
    }

}
