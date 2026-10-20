// Credenciales que se envían al endpoint de autenticación
export class LoginRequest {
    constructor(
        public readonly correo: string,
        public readonly password: string
    ) { }

    // Compara por valor, no por referencia
    equals(otro: LoginRequest): boolean {
        return this.correo === otro.correo
            && this.password === otro.password;
    }
}
