package gad.mjs.proyectos.transporte.gestionvehicular.auth.application.contacts;

import gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos.AuthResponse;
import gad.mjs.proyectos.transporte.gestionvehicular.auth.application.dtos.LogoutResponse;

public interface IAuthService {

    AuthResponse login(String correo, String password);

    AuthResponse refresh(String token);

    LogoutResponse logout(String token);

    AuthResponse changePassword(String correo, String oldPassword, String newPassword);
}
