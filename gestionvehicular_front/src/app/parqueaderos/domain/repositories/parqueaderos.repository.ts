import { Observable } from 'rxjs';
import { ActualizarParqueaderoRequest } from '../models/actualizar-parqueadero-request.model';
import { CrearParqueaderoRequest } from '../models/crear-parqueadero-request.model';
import { Parqueadero } from '../models/parqueadero.model';

export abstract class ParqueaderosRepository {
    // Listar todos los parqueaderos; la api no devuelve su estado
    abstract listar(): Observable<Parqueadero[]>;

    // Registrar un parqueadero nuevo
    abstract crear(params: CrearParqueaderoRequest): Observable<Parqueadero>;

    // Actualizar los datos, la ubicación o el estado de un parqueadero existente
    abstract actualizar(params: ActualizarParqueaderoRequest): Observable<Parqueadero>;
}
