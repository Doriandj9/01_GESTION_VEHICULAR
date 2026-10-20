package gad.mjs.proyectos.transporte.gestionvehicular.seguridades;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import org.springframework.stereotype.Service;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;

import javax.crypto.SecretKey;
import java.util.*;
import java.util.function.Function;

@Service
public class JwtService {

    @Value("${application.security.jwt.secret-key}")
    private String secretKey;

    @Value("${application.security.jwt.expiration}")
    private Long expiration;

    @Value("${application.security.jwt.refresh-token.expiration}")
    private Long refreshTokenExpiration;

    /**
     * Extrae el nombre de usuario el subject que puede ser el correo o un usuario
     * @return String
     */
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public String extractId(String token) {
        return extractClaim(token, Claims::getId);
    }


    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    /**
     *
     * @param token el token a decodifcar
     * @param claimsResolver el metodo que sirve para extraer un dato del token decodificado
     * @return T generalmente un Mapper se <String, Object>
     * @param <T> lo que pide el generico
     */
    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts
                .parser()
                .verifyWith(getSignInKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();

    }

    private SecretKey getSignInKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }


    public String buildToken(final Map<String, Object> extraData, final Usuario usuario, final long timeExpired) {
        return Jwts.builder()
                .id(usuario.getCodUsuarios().toString())
                .subject(usuario.getCorreo())
                .issuedAt(new Date(System.currentTimeMillis()))
                .claims(extraData)
                .expiration(new Date(System.currentTimeMillis() + timeExpired))
                .signWith(getSignInKey())
                .compact();
    }

    public String generateToken(final Usuario usuario, final Map<String,Object> claims) {

        return  buildToken(claims, usuario, expiration);
    }

    public String generateRefreshToken(final Usuario usuario, final Map<String, Object> claims){

        return  buildToken(claims, usuario, refreshTokenExpiration);
    }


    public boolean isValidToken(String token, String username) {
        String name = extractUsername(token);
        return  (username.equals(name) && !isTokenExpired(token));
    }

    private boolean isTokenExpired(String token) {
        Date expiration = extractExpiration(token);
        return expiration.before(new Date());
    }
}
