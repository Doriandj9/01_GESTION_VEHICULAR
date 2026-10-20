---
name: create-functionality
description: Crear una funcionalidad completa en Angular distribuida por capas (Data, Domain, Presentation) siguiendo las convenciones del proyecto Gestión Vehicular. Úsala cuando se pida crear, agregar o estructurar un módulo, pantalla, CRUD, página o funcionalidad nueva dentro de src/app (por ejemplo "crea la funcionalidad de vehículos", "agrega el módulo de conductores", "necesito la pantalla de mantenimientos").
---

# Crear una funcionalidad

Genera una funcionalidad completa por capas: `Data` (acceso a apis), `Domain`
(modelos, contratos y casos de uso) y `Presentation` (ui). El código y los
comentarios van **en español**, las clases en `PascalCase` y las funciones en
`camelCase`.

## Antes de escribir código

1. Lee `AGENTS.md` y `MEMORY.md` en la raíz del proyecto. Son obligatorios: ahí
   están las convenciones y las decisiones ya tomadas (no se vuelven a discutir).
2. Revisa `src/app/base/` para reutilizar los contratos base (`UseCase`,
   `Mapper`, `LoaderService`) en lugar de redefinirlos.
3. Confirma el nombre de la funcionalidad con el usuario solo si es ambiguo; si
   es claro, continúa.

## Estructura a crear

Crea una carpeta en `src/app` cuyo nombre **describa la funcionalidad** (en
`kebab-case`) y dentro las tres capas:

```
src/app/<funcionalidad>/
├── data/
│   ├── <funcionalidad>-impl.repository.ts
│   └── data.module.ts
├── domain/
│   ├── models/
│   │   ├── <nombre>-request.model.ts
│   │   └── <nombre>-response.model.ts
│   ├── repositories/
│   │   └── <funcionalidad>.repository.ts
│   └── usecases/
│       └── <accion>-<funcionalidad>.usecase.ts
└── presentation/
    ├── components/            (solo si se necesita)
    ├── <funcionalidad>.page.ts
    ├── <funcionalidad>.page.html
    └── <funcionalidad>.page.css
```

Reglas de dependencia: `Presentation` → `Domain` ← `Data`. `Domain` **nunca**
importa de `Data` ni de `Presentation`.

## Capa Data

Contiene los repositorios que hablan con las apis externas. La dirección de la
api **siempre** se consume desde las variables de ambiente
(`src/environments`), nunca escrita a mano. El mapeo de la respuesta cruda de la
api al modelo del dominio ocurre dentro del repositorio.

```ts
@Injectable()
export class UsuarioImplRepository extends UsuarioRepository {
    private http = inject(HttpClient);
    private urlEndpoint = `${environment.api.url}${environment.api.version}/usuarios`;

    override getPerfilByUsuario(params: GetPerfilRequest): Observable<PerfilUsuarioResponse[]> {
        // Se mapea la respuesta de la api al modelo del dominio
        return this.http.post<any[]>(`${this.urlEndpoint}/GetPerfilByUsuario`, params).pipe(
            map(responseApi => responseApi.map(item => ({
                codigoUsuario: item.codigoUsuario,
                apellidosNombres: item.apellidosNombres,
                correoElectronico: item.correoElectronicoAlterno || item.correoElectronico
            })))
        );
    }
}
```

El `DataModule` de la funcionalidad es el único lugar donde se enlaza el
contrato con su implementación:

```ts
@NgModule({
    imports: [CommonModule],
    providers: [
        { provide: UsuarioRepository, useClass: UsuarioImplRepository }
    ]
})
export class DataModule { }
```

Como el proyecto usa componentes `standalone` (Angular 22), `HttpClient` se
provee globalmente con `provideHttpClient()` en `src/app/app.config.ts` — no se
importa `HttpClientModule`. Verifica que esté registrado y agrégalo si falta.

## Capa Domain

### Modelos

Modelos de petición y de respuesta de las apis. Son **inmutables**
(`readonly`), implementan `equals` y, cuando haga falta construir variantes,
`withCopy`. No se exportan en barriles: se importan directamente desde su
archivo.

```ts
// Respuesta del perfil del usuario
export class PerfilUsuarioResponse {
    constructor(
        public readonly codigoUsuario: string,
        public readonly apellidosNombres: string,
        public readonly correoElectronico: string
    ) { }

    // Compara por valor, no por referencia
    equals(otro: PerfilUsuarioResponse): boolean {
        return this.codigoUsuario === otro.codigoUsuario
            && this.apellidosNombres === otro.apellidosNombres
            && this.correoElectronico === otro.correoElectronico;
    }

    // Devuelve una nueva instancia con los campos indicados
    withCopy(cambios: Partial<PerfilUsuarioResponse>): PerfilUsuarioResponse {
        return new PerfilUsuarioResponse(
            cambios.codigoUsuario ?? this.codigoUsuario,
            cambios.apellidosNombres ?? this.apellidosNombres,
            cambios.correoElectronico ?? this.correoElectronico
        );
    }
}
```

### Contratos de repositorio

Clases `abstract` (sirven además como token de inyección), con un método por
operación y un comentario que explique qué hace:

```ts
export abstract class UsuarioRepository {
    // Obtener perfil del usuario logueado
    abstract getPerfilByUsuario(params: GetPerfilRequest): Observable<PerfilUsuarioResponse[]>;

    // Guardar usuario externo público
    abstract saveExternoPublico(params: SaveUsuarioRequest): Observable<BaseResponseModel>;
}
```

### Casos de uso

Implementan `UseCase<S, T>` importado desde `src/app/base/abstracts.ts`. Un
caso de uso por operación, con orquestación pura: nada de `HttpClient` ni de
lógica de ui.

```ts
@Injectable({ providedIn: 'root' })
export class GetPerfilUseCase implements UseCase<GetPerfilRequest, PerfilUsuarioResponse[]> {
    constructor(private usuarioRepository: UsuarioRepository) { }

    execute(params: GetPerfilRequest): Observable<PerfilUsuarioResponse[]> {
        // Lógica de orquestación pura
        return this.usuarioRepository.getPerfilByUsuario(params);
    }
}
```

## Capa Presentation

La ui que ve el usuario, con una carpeta `components/` interna solo si se
necesita descomponer la pantalla. Por cada componente:

- **`.html`**: maquetación centrada usando `cne-panel` y `cne-form`.
- **`.ts`**: inyección de dependencias y orquestación de los casos de uso.
- **`.css`**: estilos locales de posicionamiento y layout, únicamente cuando
  Tailwind no alcanza para un estilo personalizado.

El componente principal de la page importa las capas inferiores:

```ts
// -----------------------------------------------------------
// 1. COMPONENT: PerfilUsuarioComponent.ts (Orquestador)
// -----------------------------------------------------------
@Component({
  selector: 'app-perfil-usuario',
  standalone: true,
  imports: [CommonModule, PanelComponent, FormComponent],
  templateUrl: './perfil-usuario.component.html',
  styleUrls: ['./perfil-usuario.component.css']
})
export class PerfilUsuarioComponent implements OnInit {
  private saveUseCase = inject(SaveUsuarioUseCase);

  formData: any = {};
  formElements = PerfilUsuarioConfig.getElements(() => this.goBack());

  onFormSubmit(e: any): void {
    const request = this.formData;
    this.saveUseCase.execute(request).subscribe(res => {
        this.notify.Message('Éxito', 'success');
    });
  }
}
```

Registra la page en `src/app/app.routes.ts` con `loadComponent` (carga diferida).

El `DataModule` de la funcionalidad se registra en el injector **raíz**, en
`src/app/app.config.ts`:

```ts
providers: [
    // ...
    importProvidersFrom(DataModule)
]
```

No lo pongas en los `providers` de la ruta ni en los `imports` del componente:
los casos de uso y los stores son `providedIn: 'root'`, así que el injector raíz
debe poder resolver el repositorio. Si queda más abajo, falla en tiempo de
ejecución con `NG0201: No provider found for <X>Repository`.

## Al terminar

1. Verifica que compile: `npx tsc --noEmit -p tsconfig.app.json`.
2. Si durante el trabajo se tomó una decisión nueva de arquitectura o
   convención, agrégala a `MEMORY.md` en una línea.
3. Resume al usuario los archivos creados por capa y la ruta registrada.
