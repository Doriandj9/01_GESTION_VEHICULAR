// Datos que se envían a `POST /auth/change-password`
export class ChangePasswordRequest {
    constructor(
        public readonly correo: string,
        public readonly oldPassword: string,
        public readonly newPassword: string
    ) { }

    // Compara por valor, no por referencia
    equals(otro: ChangePasswordRequest): boolean {
        return this.correo === otro.correo
            && this.oldPassword === otro.oldPassword
            && this.newPassword === otro.newPassword;
    }
}
