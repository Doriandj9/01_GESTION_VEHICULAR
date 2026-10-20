package gad.mjs.proyectos.transporte.gestionvehicular.configuraciones;

public class ApiVersionParser implements org.springframework.web.accept.ApiVersionParser {

    @Override
    public Comparable<String> parseVersion(String version) {
        //El prefixo "V" se pase a minuscula
        if(version.startsWith("V")){
            version = version.toLowerCase();
        }
        return version;
    }
}
