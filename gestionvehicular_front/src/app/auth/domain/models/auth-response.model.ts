// Tokens devueltos por `POST /auth` y `POST /auth/refresh`
export class AuthResponse {
    constructor(
        public readonly jwt: string,
        public readonly refreshToken: string,
        public readonly jwtExpired: number
    ) { }

    // Compara por valor, no por referencia
    equals(otro: AuthResponse): boolean {
        return this.jwt === otro.jwt
            && this.refreshToken === otro.refreshToken
            && this.jwtExpired === otro.jwtExpired;
    }
}
