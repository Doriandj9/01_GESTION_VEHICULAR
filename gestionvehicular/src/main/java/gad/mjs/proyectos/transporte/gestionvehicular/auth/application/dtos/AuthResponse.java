package gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos;

public record AuthResponse(
        String jwt,
        String refreshToken,
        Long jwtExpired
) {
}
