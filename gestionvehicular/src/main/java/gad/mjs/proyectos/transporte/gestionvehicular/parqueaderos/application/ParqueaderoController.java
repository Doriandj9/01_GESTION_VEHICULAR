package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.application;

import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.application.contracts.IParqueaderoService;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderResponseCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderoRequestCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderoRequestUpdate;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/{version}/parqueaderos")
@SecurityScheme(
        name = "Bearer",
        type = SecuritySchemeType.HTTP,
        bearerFormat = "JWT",
        scheme = "bearer"
)
public class ParqueaderoController {
    private final IParqueaderoService service;

    @PostMapping(version = "v1.0")
    @Operation(
            summary = "Creacion de nuevos parqueaderos",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<ParqueaderResponseCreate> create(@Valid @RequestBody ParqueaderoRequestCreate request){
        return ResponseEntity.ok(service.register(request));
    }

    @GetMapping(version = "v1.0")
    @Operation(
            summary = "Listar todos los parqueaderos",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<List<ParqueaderResponseCreate>>  listar(){
        return ResponseEntity.ok(service.listarParqueaderos());
    }

    @PutMapping(value = "/{id}", version = "v1.0")
    @Operation(
            summary = "Actualizar un parqueadero",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<ParqueaderResponseCreate>
    update(@PathVariable Long id, @Valid @RequestBody ParqueaderoRequestUpdate request){
        return ResponseEntity.ok(service.actualizarParquedero(id,request));
    }
}
