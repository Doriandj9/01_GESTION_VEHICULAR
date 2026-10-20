package gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.dtos;

import gad.mjs.proyectos.transporte.gestionvehicular.common.serializes.JsonSerialize;
import org.jspecify.annotations.NullMarked;

import java.time.LocalDateTime;
import java.util.Map;

@NullMarked
public record ErrorRestGlobalResponse(
        LocalDateTime timestamp,
        int status,
        String error,
        Map<String, String> errors,
        String message,
        String path
) implements JsonSerialize {


    public static ErrorRestGlobalResponse of(
            int status,
            String serverError,
            String message,
            String path
    ){
        return new ErrorRestGlobalResponse(
                LocalDateTime.now(),
                status,
                serverError,
                Map.of(),
                message,
                path
        );
    }

    public static ErrorRestGlobalResponse ofWithErrors(
            int status,
            String serverError,
            String message,
            Map<String, String> errors,
            String path
    ){
        return new ErrorRestGlobalResponse(
                LocalDateTime.now(),
                status,
                serverError,
                errors,
                message,
                path
        );
    }
}
