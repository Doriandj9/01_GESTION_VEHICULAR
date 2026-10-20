package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.qrcode.QRCodeWriter;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts.IQrGenerator;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.PayloadQrData;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.io.Encoders;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.io.ByteArrayOutputStream;
import java.util.Date;
import java.util.Map;
import java.util.function.Function;


@Service
@RequiredArgsConstructor
public class QrGenerator implements IQrGenerator {
    @Value("${application.qr.secret-key}")
    private String secretKey;

    @Override
    public byte[] generateQr(PayloadQrData payload) {
        try{
            String hashQr = buildToken(payload.identifier(),payload.subject(),payload.claims());

            QRCodeWriter qrCodeWriter = new QRCodeWriter();

            var arrayBytes = qrCodeWriter.encode(
                    hashQr,
                    BarcodeFormat.QR_CODE,
                    300,
                    300,
                    Map.of(EncodeHintType.MARGIN,1)
            );

            ByteArrayOutputStream output = new ByteArrayOutputStream();
                MatrixToImageWriter.writeToStream(
                        arrayBytes,
                        "PNG",
                        output
                );

                return output.toByteArray();


        }catch (WriterException | java.io.IOException e) {
            throw new IllegalStateException(
                    "Error al generar el código QR", e
            );
        }
    }

    @Override
    public boolean validateQr(String hash) {
        try {
            String id = extractClaim(hash, Claims::getId);
            return id != null && !id.isBlank();

        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    @Override
    public String toBase64(byte[] data) {
        return Encoders.BASE64.encode(data);
    }


    public  <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }


    private SecretKey getSignInKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    private Claims extractAllClaims(String token) {
        return Jwts
                .parser()
                .verifyWith(getSignInKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();

    }

    public String buildToken(String id, String subject, Map<String, Object> claims) {
        return Jwts.builder()
                .id(id)
                .subject(subject)
                .issuedAt(new Date(System.currentTimeMillis()))
                .claims(claims)
                .signWith(getSignInKey())
                .compact();
    }
}
