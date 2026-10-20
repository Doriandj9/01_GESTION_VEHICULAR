import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments';
import { AuthTokensResponse, LogoutResponse, UsuarioDetalleResponse } from '../../base/apiTypes';
import { AuthResponse } from '../domain/models/auth-response.model';
import { ChangePasswordRequest } from '../domain/models/change-password-request.model';
import { LoginRequest } from '../domain/models/login-request.model';
import { UsuarioDetalle } from '../domain/models/usuario-detalle.model';
import { AuthRepository } from '../domain/repositories/auth.repository';

@Injectable()
export class AuthImplRepository extends AuthRepository {
    private http = inject(HttpClient);
    private urlBase = `${environment.api.url}${environment.api.version}`;

    override login(params: LoginRequest): Observable<AuthResponse> {
        const cuerpo = { correo: params.correo, password: params.password };

        // Se mapea la respuesta de la api al modelo del dominio
        return this.http.post<AuthTokensResponse>(`${this.urlBase}/auth`, cuerpo).pipe(
            map(responseApi => new AuthResponse(
                responseApi.jwt,
                responseApi.refreshToken,
                responseApi.jwtExpired
            ))
        );
    }

    override getUsuarioDetalle(): Observable<UsuarioDetalle> {
        // El interceptor agrega el header Authorization con el jwt vigente
        return this.http.get<UsuarioDetalleResponse>(`${this.urlBase}/usuarios/detalle`).pipe(
            map(responseApi => new UsuarioDetalle(
                responseApi.codUsuarios,
                responseApi.nombres,
                responseApi.correo,
                responseApi.estado,
                responseApi.rol
            ))
        );
    }

    override changePassword(params: ChangePasswordRequest): Observable<AuthResponse> {
        const cuerpo = {
            correo: params.correo,
            oldPassword: params.oldPassword,
            newPassword: params.newPassword
        };

        return this.http.post<AuthTokensResponse>(`${this.urlBase}/auth/change-password`, cuerpo).pipe(
            map(responseApi => new AuthResponse(
                responseApi.jwt,
                responseApi.refreshToken,
                responseApi.jwtExpired
            ))
        );
    }

    override logout(refreshToken: string): Observable<boolean> {
        return this.http.post<LogoutResponse>(`${this.urlBase}/auth/logout`, { token: refreshToken }).pipe(
            map(responseApi => responseApi.state)
        );
    }
}
