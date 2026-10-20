package gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application;

import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.contracts.IMovimientoService;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoRequestCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseRegistrado;
import gad.mjs.proyectos.transporte.gestionvehicular.movimientos.application.dtos.MovimientoResponseReport;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Date;
import java.util.List;

@RestController
@RequestMapping("/api/{version}/movimientos")
@SecurityScheme(
        name = "Bearer",
        type = SecuritySchemeType.HTTP,
        bearerFormat = "JWT",
        scheme = "bearer"
)
@RequiredArgsConstructor
public class MovimientoController {
    /**
     * Formato de los parametros de fecha. Sin esta anotacion Spring no tiene un
     * conversor String -> java.util.Date y cae en el constructor Date(String),
     * que NO acepta ISO 8601: un ?fecha=2026-10-19T00:00:00 fallaba con 400.
     */
    private static final String FORMATO_FECHA = "yyyy-MM-dd";

    private final IMovimientoService service;


    @PostMapping(version = "v1.0")
    @Operation(
            summary = "Registrar un movimiento de un vehiculo por medio de qr-data",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<MovimientoResponse> registrar(@RequestBody @Valid MovimientoRequestCreate request){
        return ResponseEntity.ok(service.registrar(request));
    }


    @GetMapping(value = "/reporte/todos", version = "v1.0")
    @Operation(
            summary = "Obtiene los ultimos 100 movientos realizados de los vehiculos",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<List<MovimientoResponseReport>> obtenerTodos(
            @RequestParam(name = "cantidad", defaultValue = "100")
            @Min(value = 1, message = "La cantidad mínima debe ser 1")
            @Max(value = 1000, message = "La cantidad máxima permitida es 1000")
            int cantidad
    ){
        return ResponseEntity.ok(service.listarUltimosMovimientos(cantidad));
    }

    @GetMapping(value = "/reporte/por-fechas",version = "v1.0")
    @Operation(
            summary = "Obtiene los movimientos de los vehiculos de acuerdo a una " +
                    "fecha inicial y una fecha final",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<List<MovimientoResponseReport>> obtenerPorFechas(
            @RequestParam(name = "fechaInicial")
            @NotNull
            @DateTimeFormat(pattern = FORMATO_FECHA)
            LocalDate fechaInicial,
            @RequestParam(name = "fechaFinal")
            @NotNull
            @DateTimeFormat(pattern = FORMATO_FECHA)
            LocalDate fechaFinal
    ){
        return ResponseEntity.ok(service.listarPorFechaInicioYFechaFin(fechaInicial, fechaFinal));
    }

    @GetMapping(value = "/usuario", version = "v1.0")
    @Operation(
            summary = "Obtiene todos los movimientos que un usuario sobre un vehiculo desde una fecha",
            security = @SecurityRequirement(name = "Bearer")
    )
    public ResponseEntity<List<MovimientoResponseRegistrado>> listarPorUsuario(
            @RequestParam("cod")
            @NotNull
            Long codUsuario,
            @RequestParam(value = "fecha")
            @NotNull
            @DateTimeFormat(pattern = FORMATO_FECHA)
            LocalDate fecha
    ){
        return ResponseEntity.ok(service.listarMovimientosDesdePorUsuario(codUsuario, fecha));
    }
}
