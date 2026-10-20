package gad.mjs.proyectos.transporte.gestionvehicular.configuraciones;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.ResourceNotFoundException;
import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.UnauthorizedException;
import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.UsernameNotFoundException;
import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.dtos.ErrorRestGlobalResponse;
import io.jsonwebtoken.ExpiredJwtException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class RestExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorRestGlobalResponse> handleResourceNotFound(
            ResourceNotFoundException ex,
            HttpServletRequest request
    ) {
        HttpStatus status = HttpStatus.NOT_FOUND;

        return ResponseEntity.status(status).body(
                ErrorRestGlobalResponse.of(
                        status.value(),
                        ex.getMessage(),
                        "No se encontró el recurso solicitado.",
                        request.getRequestURI()
                )
        );
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ErrorRestGlobalResponse> handleBadCredentials(
            BadCredentialsException ex,
            HttpServletRequest request
    ) {
        HttpStatus status = HttpStatus.UNAUTHORIZED;

        return ResponseEntity.status(status).body(
                ErrorRestGlobalResponse.of(
                        status.value(),
                        "Autenticación fallida.",
                        "Credenciales incorrectas. Verifique e inténtelo nuevamente.",
                        request.getRequestURI()
                )
        );
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorRestGlobalResponse> handleAccessDenied(
            AccessDeniedException ex,
            HttpServletRequest request
    ) {
        HttpStatus status = HttpStatus.FORBIDDEN;

        return ResponseEntity.status(status).body(
                ErrorRestGlobalResponse.of(
                        status.value(),
                        "Acceso denegado.",
                        "No tiene permisos para realizar esta operación.",
                        request.getRequestURI()
                )
        );
    }

    @ExceptionHandler(ExpiredJwtException.class)
    public ResponseEntity<ErrorRestGlobalResponse> handleExpiredJwt(
            ExpiredJwtException ex,
            HttpServletRequest request
    ) {
        HttpStatus status = HttpStatus.UNAUTHORIZED;

        return ResponseEntity.status(status).body(
                ErrorRestGlobalResponse.of(
                        status.value(),
                        "Token expirado.",
                        "La sesión ha expirado. Inicie sesión nuevamente.",
                        request.getRequestURI()
                )
        );
    }

    @ExceptionHandler(DomainException.class)
    public ResponseEntity<ErrorRestGlobalResponse> handleDomainException(
            DomainException ex,
            HttpServletRequest request
    ) {
        HttpStatus status = HttpStatus.BAD_REQUEST;

        return ResponseEntity.status(status).body(
                ErrorRestGlobalResponse.ofWithErrors(
                        status.value(),
                        "Operación no válida.",
                        ex.getMessage(),
                        ex.getErrors(),
                        request.getRequestURI()
                )
        );
    }

    @ExceptionHandler(UsernameNotFoundException.class)
    public ResponseEntity<ErrorRestGlobalResponse> handleUsernameNotFound(
            UsernameNotFoundException ex,
            HttpServletRequest request
    ) {
        HttpStatus status = HttpStatus.UNAUTHORIZED;

        return ResponseEntity.status(status).body(
                ErrorRestGlobalResponse.of(
                        status.value(),
                        "Autenticación fallida.",
                        "Credenciales incorrectas. Verifique e inténtelo nuevamente.",
                        request.getRequestURI()
                )
        );
    }

    @ExceptionHandler(value = MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorRestGlobalResponse> handleValidationException(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        Map<String, String> errors = new LinkedHashMap<>();

        ex.getBindingResult().getFieldErrors().forEach(error ->
                errors.putIfAbsent(
                        error.getField(),
                        error.getDefaultMessage() != null
                                ? error.getDefaultMessage()
                                : "Valor inválido."
                )
        );

        HttpStatus status = HttpStatus.BAD_REQUEST;

        return ResponseEntity.status(status).body(
                ErrorRestGlobalResponse.ofWithErrors(
                        status.value(),
                        "Validación fallida.",
                        "Uno o más campos contienen errores de validación.",
                        errors,
                        request.getRequestURI()
                )
        );
    }

    @ExceptionHandler(value = UnauthorizedException.class)
    public ResponseEntity<ErrorRestGlobalResponse> handleUnauthorizedException(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        HttpStatus status = HttpStatus.BAD_REQUEST;

        return ResponseEntity.status(status).body(
                ErrorRestGlobalResponse.of(
                        status.value(),
                        "Token no proporcionado.",
                        "Por favor, envíe un token válido en la cabecera Authorization.",
                        request.getRequestURI()
                )
        );
    }
}
