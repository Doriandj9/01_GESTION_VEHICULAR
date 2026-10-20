import { HttpErrorResponse, HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, map, of, timeout } from 'rxjs';
import { environment } from '../../../environments';
import { EstadoSalud, SaludResponse } from '../../base/apiTypes';
import { SaludServidor } from '../domain/models/salud-servidor.model';
import { EstadoServidorRepository } from '../domain/repositories/estado-servidor.repository';

@Injectable()
export class EstadoServidorImplRepository extends EstadoServidorRepository {
    private http = inject(HttpClient);

    /** Url del chequeo; en desarrollo es relativa y la resuelve el proxy */
    private urlEndpoint = environment.api.urlSalud;

    override verificar(): Observable<SaludServidor> {
        return this.http.get<SaludResponse>(this.urlEndpoint).pipe(
            // Un servidor que tarda más que el tiempo de espera es tan
            // inservible como uno caído, así que no se espera indefinidamente
            timeout(environment.api.tiempoEspera),
            map(responseApi => this.aSalud(responseApi)),
            // El error también es un resultado válido para la ui
            catchError((fallo: unknown) => of(this.aSaludDesdeError(fallo)))
        );
    }

    /** Mapea la respuesta del actuator al modelo del dominio */
    private aSalud(responseApi: SaludResponse): SaludServidor {
        const estado = responseApi?.status ?? 'UNKNOWN';

        return new SaludServidor(
            estado,
            responseApi?.groups ?? [],
            this.aComponentes(responseApi),
            estado === 'UP'
                ? 'El servidor respondió correctamente.'
                : `El servidor respondió, pero informa el estado ${estado}.`
        );
    }

    /**
     * Arma el modelo cuando la petición falló. El actuator responde 503 con el
     * mismo cuerpo cuando algún componente está caído, así que en ese caso
     * todavía hay detalle que leer; si no hay cuerpo, el servidor no está
     * levantado o no se lo alcanza.
     */
    private aSaludDesdeError(fallo: unknown): SaludServidor {
        if (fallo instanceof HttpErrorResponse) {
            const cuerpo = typeof fallo.error === 'object' && fallo.error !== null
                ? fallo.error as SaludResponse
                : null;

            if (cuerpo?.status) {
                return new SaludServidor(
                    cuerpo.status,
                    cuerpo.groups ?? [],
                    this.aComponentes(cuerpo),
                    `El servidor respondió ${fallo.status} e informa el estado ${cuerpo.status}.`
                );
            }

            // Status 0: no hubo respuesta http (servidor apagado, dns, cors)
            if (fallo.status === 0) {
                return this.inalcanzable(
                    `No se obtuvo respuesta de ${this.urlEndpoint}. El servidor no está levantado, `
                    + 'no se lo alcanza desde esta red o está rechazando la conexión.'
                );
            }

            return this.inalcanzable(
                `El chequeo de salud respondió ${fallo.status} ${fallo.statusText || ''}`.trim()
                + ` en ${this.urlEndpoint}.`
            );
        }

        // Aquí cae el `timeout` y cualquier otro error inesperado
        const motivo = fallo instanceof Error ? fallo.message : 'Error desconocido';

        return this.inalcanzable(
            `No se pudo verificar ${this.urlEndpoint} (${motivo}). `
            + `El servidor no respondió dentro de ${environment.api.tiempoEspera} ms.`
        );
    }

    /** Aplana el mapa de componentes del actuator a `nombre: estado` */
    private aComponentes(responseApi: SaludResponse | null): Record<string, EstadoSalud> {
        const componentes: Record<string, EstadoSalud> = {};

        for (const [nombre, detalle] of Object.entries(responseApi?.components ?? {})) {
            componentes[nombre] = detalle?.status ?? 'UNKNOWN';
        }

        return componentes;
    }

    /** Modelo de un servidor que no se pudo consultar */
    private inalcanzable(detalle: string): SaludServidor {
        return new SaludServidor('UNKNOWN', [], {}, detalle);
    }
}
