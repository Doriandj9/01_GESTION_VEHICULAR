package gad.mjs.proyectos.transporte.gestionvehicular.pruebas;


import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.jspecify.annotations.NullMarked;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/{version}")
@Deprecated
@SecurityScheme(
        name = "Bearer",
        type = SecuritySchemeType.HTTP,
        bearerFormat = "JWT",
        scheme = "bearer"
)
public class Info {

    @GetMapping(value = "/info/media",version = "v1.0", produces = "application/json")
    @NullMarked
    @Operation(
            summary = "Información",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<String> info(){
        return ResponseEntity.ok("Info");
    }

    @GetMapping(path = "/info/media",version = "v2.0", produces = "application/json")
    @NullMarked
    @Operation(summary = "Es la segunda version de lo simple", security = @SecurityRequirement(name = "Bearer"))

    public ResponseEntity<String> infov2(){
        return ResponseEntity.ok("Info22");
    }
}
