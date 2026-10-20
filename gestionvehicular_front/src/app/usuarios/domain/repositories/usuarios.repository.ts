import { Observable } from 'rxjs';
import { ActualizarUsuarioRequest } from '../models/actualizar-usuario-request.model';
import { CrearUsuarioRequest } from '../models/crear-usuario-request.model';
import { Usuario } from '../models/usuario.model';

export abstract class UsuariosRepository {
    // Listar todos los usuarios registrados; la api no devuelve su estado
    abstract listar(): Observable<Usuario[]>;

    // Registrar un usuario nuevo; nace en estado INICIAL con una clave temporal
    abstract crear(params: CrearUsuarioRequest): Observable<Usuario>;

    // Actualizar los datos, el rol o el estado de un usuario existente
    abstract actualizar(params: ActualizarUsuarioRequest): Observable<Usuario>;
}
