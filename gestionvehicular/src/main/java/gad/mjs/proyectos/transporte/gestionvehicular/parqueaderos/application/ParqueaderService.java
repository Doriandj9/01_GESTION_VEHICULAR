package gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.application;

import gad.mjs.proyectos.transporte.gestionvehicular.common.exceptions.DomainException;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.application.contracts.IParqueaderoService;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.application.mappers.ParqueaderoMapper;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.Parqueadero;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.estados.EstadosParqueadero;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.domain.mappers.ParqueaderoDomainMapper;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderResponseCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderoRequestCreate;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.dtos.ParqueaderoRequestUpdate;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.infrastructure.ParqueaderoJpa;
import gad.mjs.proyectos.transporte.gestionvehicular.parqueaderos.infrastructure.ParqueaderoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.StreamSupport;

@Service
@RequiredArgsConstructor
public class ParqueaderService implements IParqueaderoService {
    private final ParqueaderoRepository parqueaderoRepository;
    private final ParqueaderoMapper parqueaderoMapper;
    private final ParqueaderoDomainMapper  parqueaderoDomainMapper;

    @Override
    public ParqueaderResponseCreate register(ParqueaderoRequestCreate request) {

        if(parqueaderoRepository.existsByNombreIgnoreCase(request.nombre().trim())){
            throw new DomainException("El nombre del parqueadero ya existe");
        }

        Parqueadero parqueadero = new Parqueadero(
                null,
                request.nombre().trim(),
                request.callePrincipal(),
                request.calleSecundaria(),
                request.latitud(),
                request.longitud(),
                request.urlDireccion(),
                EstadosParqueadero.ACTIVO
        );

        var result = parqueaderoRepository.save(parqueaderoDomainMapper.toJpa(parqueadero));

        return parqueaderoMapper.toResponse(parqueaderoDomainMapper.toDomain(result));
    }

    @Override
    public List<ParqueaderResponseCreate> listarParqueaderos() {
       return parqueaderoRepository.findAllByOrderByFechaCreacionDesc().stream().map(parqueaderoDomainMapper::toDomain).map(parqueaderoMapper::toResponse).toList();
    }

    @Override
    public ParqueaderResponseCreate actualizarParquedero(Long codParqueadero,ParqueaderoRequestUpdate request) {
        ParqueaderoJpa parqueaderoJpa = parqueaderoRepository.findById(codParqueadero)
                .orElseThrow(() -> new DomainException("El parqueadero no existe"));

        Parqueadero parqueadero = parqueaderoMapper.toUpdateParqueadero(parqueaderoDomainMapper.toDomain(parqueaderoJpa),request);

        parqueadero = parqueaderoDomainMapper.toDomain(parqueaderoRepository.save(parqueaderoDomainMapper.toJpa(parqueadero)));

        return parqueaderoMapper.toResponse(parqueadero);
    }

}
