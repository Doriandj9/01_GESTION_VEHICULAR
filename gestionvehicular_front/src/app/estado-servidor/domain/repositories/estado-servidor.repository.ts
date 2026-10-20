import { Observable } from 'rxjs';
import { SaludServidor } from '../models/salud-servidor.model';

export abstract class EstadoServidorRepository {
    /**
     * Consulta el chequeo de salud del backend. Nunca falla: un servidor caído
     * o inalcanzable también se devuelve como un `SaludServidor`, porque ese es
     * justamente el resultado que la ui necesita mostrar.
     */
    abstract verificar(): Observable<SaludServidor>;
}
