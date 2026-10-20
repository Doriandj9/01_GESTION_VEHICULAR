package gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.contacts;

import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.VehiculoRequestUpdate;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.VehiculoResponseCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.registro_vehicular.application.dtos.VehiculoRequestCreate;

import java.util.List;

public interface IVehiculoService {

    VehiculoResponseCreate registrar(VehiculoRequestCreate request);

    List<VehiculoResponseCreate> listarVehiculos();

    VehiculoResponseCreate actualizar(Long codVehiculo, VehiculoRequestUpdate request);

    VehiculoResponseCreate obtenerVehiculo(Long codVehiculo);

}
