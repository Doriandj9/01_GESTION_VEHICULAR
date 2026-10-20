package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.application.contracts;

import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.Parqueadero;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderResponseCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderoRequestCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderoRequestUpdate;

import java.util.List;

public interface IParqueaderoService {
    ParqueaderResponseCreate register(ParqueaderoRequestCreate request);
    List<ParqueaderResponseCreate> listarParqueaderos();
    ParqueaderResponseCreate actualizarParquedero(Long codParqueadero, ParqueaderoRequestUpdate request);
}
