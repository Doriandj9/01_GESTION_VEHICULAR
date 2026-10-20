import { Observable } from 'rxjs';
import { ActualizarVehiculoRequest } from '../models/actualizar-vehiculo-request.model';
import { CrearVehiculoRequest } from '../models/crear-vehiculo-request.model';
import { Vehiculo } from '../models/vehiculo.model';

export abstract class RegistroVehicularRepository {
    // Listar todos los vehículos registrados
    abstract listar(): Observable<Vehiculo[]>;

    // Obtener un vehículo por su código
    abstract obtenerPorId(codVehiculo: number): Observable<Vehiculo>;

    // Registrar un vehículo nuevo asignado a un parqueadero; la api genera su QR
    abstract crear(params: CrearVehiculoRequest): Observable<Vehiculo>;

    // Actualizar los datos, el parqueadero o el estado de un vehículo existente
    abstract actualizar(params: ActualizarVehiculoRequest): Observable<Vehiculo>;
}
