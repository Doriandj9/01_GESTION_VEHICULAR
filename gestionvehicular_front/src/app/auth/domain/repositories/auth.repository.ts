import { Observable } from 'rxjs';
import { ChangePasswordRequest } from '../models/change-password-request.model';
import { LoginRequest } from '../models/login-request.model';
import { AuthResponse } from '../models/auth-response.model';
import { UsuarioDetalle } from '../models/usuario-detalle.model';

export abstract class AuthRepository {
    // Autenticar al usuario con su correo electrónico y su clave (endpoint público)
    abstract login(params: LoginRequest): Observable<AuthResponse>;

    // Obtener los datos y el rol del usuario dueño del jwt
    abstract getUsuarioDetalle(): Observable<UsuarioDetalle>;

    // Cambiar la clave del usuario autenticado; devuelve tokens nuevos
    abstract changePassword(params: ChangePasswordRequest): Observable<AuthResponse>;

    // Cerrar la sesión del refresh token en el backend
    abstract logout(refreshToken: string): Observable<boolean>;
}
