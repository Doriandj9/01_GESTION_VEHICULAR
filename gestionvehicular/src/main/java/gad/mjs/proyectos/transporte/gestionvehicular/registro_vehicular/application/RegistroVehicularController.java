package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application;


import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts.IVehiculoService;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.VehiculoRequestUpdate;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.VehiculoResponseCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.VehiculoRequestCreate;
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
@RequestMapping("/api/{version}/registro_vehicular")
@RequiredArgsConstructor
@SecurityScheme(
        name = "Bearer",
        type = SecuritySchemeType.HTTP,
        bearerFormat = "JWT",
        scheme = "bearer"
)
public class RegistroVehicularController {
    private final IVehiculoService service;

    @PostMapping(version = "v1.0")
    @Operation(
            summary = "Creacion de un heviculo asignado a un parqueadero",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<VehiculoResponseCreate> create(@RequestBody VehiculoRequestCreate request){
        return ResponseEntity.ok(service.registrar(request));
    }

    @GetMapping(version = "v1.0")
    @Operation(
            summary = "Listar todos los vehiculos registrados."
    )
    public ResponseEntity<List<VehiculoResponseCreate>> listar(){
        return ResponseEntity.ok(service.listarVehiculos());
    }


    @PutMapping(value = "/{id}", version = "v1.0")
    @Operation(
            summary = "Actualizar un vehiculo",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<VehiculoResponseCreate>
    actualizar(
            @PathVariable Long id,
            @Valid @RequestBody VehiculoRequestUpdate request
    ){
        return ResponseEntity.ok(service.actualizar(id, request));
    }

    @GetMapping(value = "/{id}", version = "v1.0")
    @Operation(
            summary = "Obtener un vehiculo por id",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<VehiculoResponseCreate>
    listarVehiculoPorId(@PathVariable Long id){
        return ResponseEntity.ok(service.obtenerVehiculo(id));
    }
}

