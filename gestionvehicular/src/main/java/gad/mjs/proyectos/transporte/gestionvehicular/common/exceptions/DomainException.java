package gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions;

import lombok.Getter;

import java.util.HashMap;
import java.util.Map;

public class DomainException extends RuntimeException {
    @Getter
    private Map<String,String> errors = new HashMap<>();

    public DomainException(String message) {
        super(message);
    }

    public DomainException(String message,  Map<String,String> errors) {
        super(message);
        this.errors = errors;
    }
}
