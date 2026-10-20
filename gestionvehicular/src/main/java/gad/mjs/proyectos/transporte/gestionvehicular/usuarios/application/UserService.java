package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.seguridades.JwtService;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.contracts.IUserService;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos.UsuarioDetalle;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos.UsuarioResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.mappers.UserMapper;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Rol;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.estados.EstadosUsuario;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.roles.Roles;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure.RolRepository;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.infrastructure.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.hibernate.Hibernate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.StreamSupport;

@Service
@RequiredArgsConstructor
public class UserService implements IUserService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final RolRepository rolRepository;
    private final UserMapper  userMapper;
    private final JwtService jwtService;
    @Value("${application.security.default-password}")
    private String defaultPassword;

    @Transactional
    @Override
    public Usuario usuarioConRol(String correo) {
        Usuario usuario =  usuarioRepository.findByCorreo(correo)
                .orElse(null);

        if(usuario != null && !Hibernate.isInitialized(usuario.getRol())){
            Hibernate.initialize(usuario.getRol());
        }

        return usuario;
    }

    @Override
    public UsuarioResponse registrarUsuario(String nombres, String correo, String rol) {
        Roles currentRol = Roles.valueOf(rol);

        Rol rolJpa=  rolRepository.findByRol(currentRol).orElseThrow(() -> new DomainException("Rol no encontrado"));

        if(usuarioRepository.existsByCorreo(correo)){
            throw new DomainException("El usuario ya existe");
        }

        Usuario usuario = new Usuario(nombres,correo,passwordEncoder.encode(defaultPassword), EstadosUsuario.INICIAL, rolJpa);

        return userMapper.toResponse(usuarioRepository.save(usuario));
    }

    @Override
    public List<UsuarioResponse> listarUsuarios() {
        List<Usuario>  usuarios = StreamSupport.stream(usuarioRepository.findAll().spliterator(), false).toList();
        return usuarios.stream().map(userMapper::toResponse).toList();
    }

    @Transactional
    @Override
    public Usuario actualizarUsuario(Long codUsuario, String nombres, String correo, String password, String rol, String estado) {
        Usuario usuario = usuarioRepository.findById(codUsuario).orElseThrow(() -> new DomainException("Usuario no encontrado"));
        Rol currentRol = null;
        if(rol != null){
            currentRol = rolRepository.findByRol(Roles.valueOf(rol)).orElseThrow(() -> new DomainException("Rol no encontrado"));
        }

        Map<String, Object> campos = new HashMap<>();
        campos.put("nombres", nombres);
        campos.put("correo", correo);
        campos.put("password", password);
        campos.put("rol", rol);
        campos.put("estado", estado);

        usuario = userMapper.toUpdateUsuario(usuario,campos);

        if(currentRol != null){
            usuario.setRol(currentRol);
        }

        return usuarioRepository.save(usuario);
    }

    @Transactional
    @Override
    public UsuarioDetalle detalleUsuarioPorToken(String token) {
        String correo = jwtService.extractUsername(token);
        Usuario usuario  = usuarioRepository.findByCorreo(correo)
                .orElseThrow(() -> new DomainException("Usuario no encontrado"));
        if(!Hibernate.isInitialized(usuario.getRol())){
            Hibernate.initialize(usuario.getRol());
        }

        return new UsuarioDetalle(
                usuario.getCodUsuarios(),
                usuario.getNombres(),
                usuario.getCorreo(),
                usuario.getEstado().name(),
                usuario.getRol().getRol().name()
        );
    }
}
