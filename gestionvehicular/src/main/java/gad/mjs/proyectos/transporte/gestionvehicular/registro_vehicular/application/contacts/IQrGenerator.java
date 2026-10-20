package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.PayloadQrData;
import io.jsonwebtoken.Claims;

import java.util.function.Function;

public interface IQrGenerator {
    byte[] generateQr(PayloadQrData payload);

    boolean validateQr(String hash);

    String toBase64(byte[] data);

    <T> T extractClaim(String token, Function<Claims, T> claimsResolver);
}
