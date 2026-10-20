import { Observable } from "rxjs";

// Contrato para Casos de Uso
export interface UseCase<S, T> {
    execute(params: S): Observable<T>;
}

// Clase base para Mapeo de Objetos
export abstract class Mapper<I, O> {
    abstract mapFrom(param: I): O;
    abstract mapTo(param: O): I;
}