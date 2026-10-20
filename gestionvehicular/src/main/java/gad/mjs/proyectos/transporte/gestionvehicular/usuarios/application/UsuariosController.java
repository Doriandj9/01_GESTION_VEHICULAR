package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.contracts.IUserService;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos.UsuarioDetalle;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos.UsuarioRequestCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos.UsuarioRequestUpdate;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos.UsuarioResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/{version}/usuarios")
@SecurityScheme(
        name = "Bearer",
        type = SecuritySchemeType.HTTP,
        bearerFormat = "JWT",
        scheme = "bearer"
)
public class UsuariosController {
    private final IUserService service;

    @PostMapping(version = "v1.0")
    @Operation(
            summary = "Creacion de usuario",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<UsuarioResponse> register(@RequestBody @Valid UsuarioRequestCreate request){
        return ResponseEntity.ok(service.registrarUsuario(request.nombre(),request.correo(),request.rol()));
    }

    @GetMapping(value = "/detalle", version = "v1.0")
    @Operation(
            summary = "Datos del usurio con su rol",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<UsuarioDetalle> detalle(
            @RequestHeader(name = HttpHeaders.AUTHORIZATION, required = false) String authorization){
        // Los nombres de cabecera son insensibles a mayusculas y hay clientes que
        // las envian en minuscula (dart:io lo hace siempre, y HTTP/2 lo exige).
        // Por eso se enlaza la cabecera por nombre, que Spring resuelve con
        // request.getHeader(), y no con headers.get("Authorization"), que es una
        // busqueda sensible a mayusculas sobre el Map y devolvia null.
        if (authorization == null || !authorization.regionMatches(true, 0, "Bearer ", 0, 7)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Token no encontrado.");
        }

        String token = authorization.substring(7).trim();
        return ResponseEntity.ok(service.detalleUsuarioPorToken(token));
    }

    @PutMapping(value = "/{id}", version = "v1.0")
    @Operation(
            summary = "Actualizacion de datos usuarios",
            security =  @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<Usuario> update( @PathVariable Long id, @RequestBody @Valid UsuarioRequestUpdate request ){
        String rol = request.rol() != null ? request.rol().name() : null;
        String estado = request.estado() != null ? request.estado().name() : null;

        return ResponseEntity.ok(service.actualizarUsuario(id,request.nombres(),request.correo(),request.password(),rol,estado));
    }

    @GetMapping(version = "v1.0")
    @Operation(
            summary = "Listado de todos los usuarios",
            security = @SecurityRequirement(name = "Bearer")
    )
    public  ResponseEntity<List<UsuarioResponse>> listAll(){
        return ResponseEntity.ok(service.listarUsuarios());
    }

}
