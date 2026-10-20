
package gad.mjs.proyectos.transporte.gestionvehicular.seguridades;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.dtos.ErrorRestGlobalResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.contracts.IUserService;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Token;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.UserDetailsMapper;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.tokens.TokenType;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure.TokenRepository;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.jspecify.annotations.NullMarked;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
@Slf4j
@NullMarked
public class SecurityFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final TokenRepository tokenRepository;
    private final UserDetailsMapper userDetailsMapper;
    private final IUserService userService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        try {
            // 1. Si ya existe una autenticación, continuar.
            if (SecurityContextHolder.getContext().getAuthentication() != null) {
                filterChain.doFilter(request, response);
                return;
            }

            // 2. Obtener la cabecera Authorization.
            final String authorization =
                    request.getHeader(HttpHeaders.AUTHORIZATION);

            // Si no existe un Bearer token, dejar que Spring Security
            // determine si el endpoint es público o protegido.
            if (authorization == null || !authorization.startsWith("Bearer ")) {
                filterChain.doFilter(request, response);
                return;
            }

            // 3. Extraer el JWT.
            final String jwt = authorization.substring(7);

            if (jwt.isBlank()) {
                sendSecurityError(
                        request,
                        response,
                        HttpStatus.UNAUTHORIZED,
                        "Token no proporcionado.",
                        "Por favor, envíe un token válido en la cabecera Authorization."
                );
                return;
            }

            // 4. Extraer el usuario del JWT.
            final String username = jwtService.extractUsername(jwt);

            if (username == null || username.isBlank()) {
                sendSecurityError(
                        request,
                        response,
                        HttpStatus.UNAUTHORIZED,
                        "Token inválido.",
                        "El token no contiene un usuario válido."
                );
                return;
            }

            // 5. Validar firma, expiración y usuario del token.
            if (!jwtService.isValidToken(jwt, username)) {
                sendSecurityError(
                        request,
                        response,
                        HttpStatus.UNAUTHORIZED,
                        "Token inválido.",
                        "El token proporcionado no es válido."
                );
                return;
            }

            // 6. Obtener el tipo de token.
            final String type = jwtService.extractClaim(
                    jwt,
                    claims -> claims.get("type", String.class)
            );

            final TokenType tokenType;

            try {
                tokenType = TokenType.valueOf(type);
            } catch (IllegalArgumentException | NullPointerException e) {
                sendSecurityError(
                        request,
                        response,
                        HttpStatus.UNAUTHORIZED,
                        "Tipo de token inválido.",
                        "El token no contiene un tipo de autenticación válido."
                );
                return;
            }

            // 7. Comprobar que el tipo de token corresponda al endpoint.
            if (!isTokenTypeForRequest(request, tokenType)) {
                sendSecurityError(
                        request,
                        response,
                        HttpStatus.UNAUTHORIZED,
                        "Tipo de token no permitido.",
                        "Por favor, envíe un token válido para este recurso."
                );
                return;
            }

            // 8. Si es un refresh token, comprobar su estado en la BD.
            if (tokenType == TokenType.REFRESH_TOKEN) {
                Token token = tokenRepository.findByToken(jwt).orElse(null);

                if (token == null) {
                    sendSecurityError(
                            request,
                            response,
                            HttpStatus.UNAUTHORIZED,
                            "Refresh token no encontrado.",
                            "El token de renovación no está registrado o ya no es válido."
                    );
                    return;
                }

                if (token.isExpired() || token.isRevoke()) {
                    sendSecurityError(
                            request,
                            response,
                            HttpStatus.UNAUTHORIZED,
                            "Refresh token inválido.",
                            "El token de renovación ha expirado o ha sido revocado."
                    );
                    return;
                }
            }

            // 9. Obtener el usuario desde la base de datos.
            Usuario usuario = userService.usuarioConRol(username);

            if (usuario == null) {
                sendSecurityError(
                        request,
                        response,
                        HttpStatus.UNAUTHORIZED,
                        "Usuario no encontrado.",
                        "No existe un usuario asociado al token proporcionado."
                );
                return;
            }

            // 10. Validar nuevamente el token contra el correo del usuario.
            if (!jwtService.isValidToken(jwt, usuario.getCorreo())) {
                sendSecurityError(
                        request,
                        response,
                        HttpStatus.UNAUTHORIZED,
                        "Token inválido.",
                        "El token no corresponde a las credenciales del usuario."
                );
                return;
            }

            // 11. Crear la autenticación de Spring Security.
            UserDetails userDetails =
                    userDetailsMapper.toUserDetails(usuario);

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            userDetails,
                            null,
                            userDetails.getAuthorities()
                    );

            authentication.setDetails(
                    new WebAuthenticationDetailsSource()
                            .buildDetails(request)
            );

            // 12. Registrar la autenticación.
            SecurityContextHolder.getContext()
                    .setAuthentication(authentication);

            // 13. Continuar con la cadena de filtros.
            filterChain.doFilter(request, response);

        } catch (ExpiredJwtException e) {
            sendSecurityError(
                    request,
                    response,
                    HttpStatus.UNAUTHORIZED,
                    "El token ha expirado.",
                    "Por favor, renueve su sesión o inicie sesión nuevamente."
            );

        } catch (JwtException e) {
            log.debug("JWT inválido: {}", e.getMessage());

            SecurityContextHolder.clearContext();

            sendSecurityError(
                    request,
                    response,
                    HttpStatus.UNAUTHORIZED,
                    "Token inválido.",
                    "La firma, estructura o contenido del token no es válido."
            );
        }
    }

    /**
     * Escribe una respuesta JSON personalizada directamente en el cuerpo HTTP.
     */
    private void sendSecurityError(
            HttpServletRequest request,
            HttpServletResponse response,
            HttpStatus status,
            String message,
            String detail
    ) throws IOException {

        if (response.isCommitted()) {
            return;
        }

        SecurityContextHolder.clearContext();

        response.setStatus(status.value());
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        response.getWriter().write(
                ErrorRestGlobalResponse.of(
                        status.value(),
                        message,
                        detail,
                        request.getRequestURI()
                ).toJson()
        );

        response.getWriter().flush();
    }

    /**
     * Determina qué tipo de token acepta cada endpoint.
     */
    public boolean isTokenTypeForRequest(
            HttpServletRequest request,
            TokenType tokenType
    ) {
        String path = request.getRequestURI();

        if (path.equals("/api/v1.0/auth/refresh")) {
            return tokenType == TokenType.REFRESH_TOKEN;
        }

        return tokenType == TokenType.ACCESS_TOKEN;
    }
}
