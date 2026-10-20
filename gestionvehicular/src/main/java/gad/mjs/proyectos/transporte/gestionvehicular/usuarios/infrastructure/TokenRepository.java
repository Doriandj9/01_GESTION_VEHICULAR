package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Token;
import org.jspecify.annotations.NullMarked;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

@NullMarked
public interface TokenRepository  extends CrudRepository<Token,Long> {

    Optional<Token> findByToken(String token);
    Optional<Token> findFirstByUsuario_CodUsuarios(Long codUsuarios);

    @Modifying
    @Query("""
    UPDATE Token t set t.revoke = :revoke
        WHERE t.usuario.codUsuarios = :codUsuarios
    """)
    int updateRevokedAllByUser(@Param("codUsuarios") Long codUsuarios, @Param("revoke") boolean revoke);
}
