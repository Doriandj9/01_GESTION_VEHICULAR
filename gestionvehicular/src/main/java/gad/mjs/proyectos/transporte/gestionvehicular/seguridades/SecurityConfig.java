package gad.mjs.proyectos.transporte.gestionvehicular.seguridades;

import gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos.LogoutResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.dtos.ErrorRestGlobalResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Token;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure.TokenRepository;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.CsrfConfigurer;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.util.Optional;

@Configuration
@RequiredArgsConstructor
@EnableWebSecurity
public class SecurityConfig {

    private final SecurityFilter securityFilter;
    private final AuthenticationProvider  authenticationProvider;
    private final TokenRepository tokenRepository;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http
                .csrf(CsrfConfigurer::disable)
                .cors(Customizer.withDefaults())
                .headers( headers -> headers
                        .frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests( authReq ->
                    authReq
                            .requestMatchers(HttpMethod.POST, "/api/v1.0/auth/**","/api/v2.0/auth/**","/api/1.0/auth/**","/api/2.0/auth/**").permitAll()
                            .requestMatchers(HttpMethod.GET, "/api/{version}/usuarios/detalle").authenticated()
                            .requestMatchers("/api/{version}/usuarios/**").hasRole("ADMINISTRADOR")

                            .requestMatchers("/swagger-ui.html","/swagger-ui/index.html","/v3/api-docs","/v3/api-docs/**","/actuator", "/actuator/**","/h2-console","/h2-console/**", "/swagger-ui/**","/favicon.ico").permitAll()

                            .requestMatchers("/error").permitAll()

                            .anyRequest().authenticated()
                )
                .authenticationProvider(authenticationProvider)
                .addFilterBefore(securityFilter, UsernamePasswordAuthenticationFilter.class)
                .logout( logout -> {
                    logout.logoutUrl("/api/v1.0/auth/logout")
                            .addLogoutHandler((request, response, authentication) -> {
                                if(!logout(response, request)){
                                    throw new IllegalArgumentException("Error de serividor");
                                }
                            })
                            .logoutSuccessHandler((request, response, authentication) -> {
                                response.setStatus(HttpStatus.OK.value());
                                response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                                response.getWriter().write(
                                        new ObjectMapper().writeValueAsString(
                                                new LogoutResponse(true, "success")
                                        )
                                );
                            });
                })

        ;
        return http.build();
    }

    private boolean logout( HttpServletResponse response, HttpServletRequest request) {
        try {
            String token = request.getHeader(HttpHeaders.AUTHORIZATION);
            if(token == null || !token.startsWith("Bearer ")) {
                sendSecurityError(
                        request,
                        response,
                        HttpStatus.UNAUTHORIZED,
                        "Token no autorizado.",
                        "Por favor, envíe un token válido en la cabecera Authorization."
                );
                return false;
            }

            String jwtToken = token.substring(7);
            Optional<Token> jwTokenOP = tokenRepository.findByToken(jwtToken);
            if(jwTokenOP.isEmpty()) {
                sendSecurityError(
                        request,
                        response,
                        HttpStatus.UNAUTHORIZED,
                        "Token no proporcionado.",
                        "Token inválido o caducado"
                );
                return false;
            }
            Token jwToken = jwTokenOP.get();

            jwToken.setRevoke(true);
            jwToken.setExpired(true);
            tokenRepository.save(jwToken);
            return true;
        }catch (Exception ex){
            response.setStatus(HttpStatus.UNAUTHORIZED.value());
            return false;
        }
    }

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
}
