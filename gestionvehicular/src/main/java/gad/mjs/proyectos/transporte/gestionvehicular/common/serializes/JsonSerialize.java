package gad.mjs.proyectos.transporte.gestionvehicular.common.serializes;

import tools.jackson.databind.ObjectMapper;

public interface JsonSerialize {

    ObjectMapper mapper = new ObjectMapper();

    default String toJson(){
        return mapper.writeValueAsString(this);
    }
}
