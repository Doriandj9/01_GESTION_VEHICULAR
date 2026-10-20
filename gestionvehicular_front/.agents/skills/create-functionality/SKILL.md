---
name: create-functionality 
description: Crear un nuevo funcionalidad completa distribuido por capas siguiendo las convenciones del proyecto

---

# Crear una funcionalidad
1. lee `AGENTS.md` y `MEMORY.md` antes de escribir algún código
2. Crea una capeta dentro scr/app con el nombre que describa a la funcionalidad 
3. Crea la estructura de carpetas dentro de la funcionalidad
- `Data` Aquí deben colocarse los repositories que se comunican con las apis externas se debe consumir la dirección desde las variables ambiente y también el DataModule que exporte el repository asi:

```
// Ejemplo de implementación de repositorio
return this.http.post<any[]>(`${this.urlEndpoint}/GetPerfilByUsuario`, params).pipe(
    map(responseApi => responseApi.map(item => ({
        codigoUsuario: item.codigoUsuario,
        apellidosNombres: item.apellidosNombres,
        correoElectronico: item.correoElectronicoAlterno || item.correoElectronico
    })))
);
```

```
//El modulo que exporta

@NgModule({
    imports: [CommonModule, HttpClientModule],
    providers: [
        { provide: UsuarioRepository, useClass: UsuarioImplRepository }
    ]
})
export class DataModule { }
```
- `Domain` Aquí debe estar los modelos de respuesta de apis y para enviar apis, estos deben implementar lo que todo modelo tener equals, withCopy y deben ser inmutables el withCopy según sea necesario, estos modelos no necesitan ser exportados solo se los debe llamar de manera directa. También aquí deben estar los casos de uso que se comunica con los repositorios en esta capa se encuentran los contratos de los repositorios como ejemplo:
```
export abstract class UsuarioRepository {
    // Obtener perfil del usuario logueado
    abstract getPerfilByUsuario(params: GetPerfilRequest): Observable<PerfilUsuarioResponse[]>;
    
    // Guardar usuario externo público
    abstract saveExternoPublico(params: SaveUsuarioRequest): Observable<BaseResponseModel>;
}
```
ejemplo de un caso de uso:

```
@Injectable({ providedIn: 'root' })
export class GetPerfilUseCase implements UseCase<GetPerfilRequest, PerfilUsuarioResponse[]> {
    constructor(private usuarioRepository: UsuarioRepository) { }

    execute(params: GetPerfilRequest): Observable<PerfilUsuarioResponse[]> {
        // Lógica de orquestación pura
        return this.usuarioRepository.getPerfilByUsuario(params);
    }
}

```

para implementar `UseCase` se debe importar de `/app/src/base/**`


- `Presentation` Aquí se encuentran las ui que se presenta al usuario internamente puede tener una carpeta `Componentes` de ser necesario se debe cumplir estas reglas:
* component.html: Maquetación centrada usando cne-panel y cne-form.
* component.ts: Inyección de dependencias y orquestación de UseCases.
* component.css: Estilos locales para el posicionamiento y layout en caso de que se necesite estilos personalizados que se encuentra con tailwindcss 

En el componente principal de la page se debe importar las capas inferiores ejemplo:

```
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
    const request = this.formData
    this.saveUseCase.execute(request).subscribe(res => {
        this.notify.Message('Éxito', 'success');
    });
  }
}
```



