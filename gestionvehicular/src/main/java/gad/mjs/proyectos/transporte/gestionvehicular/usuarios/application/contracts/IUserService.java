package gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.contracts;

import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos.UsuarioDetalle;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.application.dtos.UsuarioResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.usuarios.domain.Usuario;

import java.util.List;

public interface IUserService {

    Usuario usuarioConRol(String correo);

    UsuarioResponse registrarUsuario(String nombres, String correo, String rol );

    List<UsuarioResponse> listarUsuarios();

    Usuario actualizarUsuario(Long codUsuario, String nombres, String correo, String password, String rol, String estado);

    UsuarioDetalle detalleUsuarioPorToken(String token);
}
