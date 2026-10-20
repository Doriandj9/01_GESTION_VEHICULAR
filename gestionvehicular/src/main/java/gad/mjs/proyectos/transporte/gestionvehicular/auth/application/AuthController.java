package gad.mjs.proyectos.transporte.gestionvehicular.auth.application;

import gad.mjs.proyectos.transporte.gestionvehicular.auth.application.contacts.IAuthService;
import gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NullMarked;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/{version}")
@RequiredArgsConstructor
@NullMarked
@SecurityScheme(
        name = "Bearer",
        type = SecuritySchemeType.HTTP,
        bearerFormat = "JWT",
        scheme = "bearer"
)
public class AuthController {

    private final IAuthService authService;

    @PostMapping(value = "/auth", version = "v1.0")
    @Operation(
            summary = "Autenticar un usuario"
    )
    public ResponseEntity<AuthResponse> login(@RequestBody @Valid AuthRequest request){
        final var response = this.authService.login(request.correo(),request.password());
        return ResponseEntity.ok(response);
    }

    @PostMapping(value = "/auth/refresh", version = "v1.0")
    @Operation(
            summary = "Refrescar un token",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<AuthResponse> refresh(@RequestBody @Valid AuthRefresh request){
        final var response = this.authService.refresh(request.token());
        return ResponseEntity.ok(response);
    }

    @PostMapping(value = "/auth/logout", version = "v1.0")
    @Operation(
            summary = "Cerrar la session de un token",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<LogoutResponse> logout(@RequestBody @Valid AuthRefresh request){
        final var response = this.authService.logout(request.token());
        return ResponseEntity.ok(response);
    }

    @PostMapping(value = "/auth/change-password", version = "v1.0")
    @Operation(
            summary = "Cambiar de clave de un usuario",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<AuthResponse> changePassword(@RequestBody @Valid AuthRequestChangePassword request){
        return ResponseEntity.ok(this.authService.changePassword(request.correo(),request.oldPassword(), request.newPassword()));
    }
}
