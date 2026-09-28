# Demo: entorno de QA dinámico en Azure

Demo de un entorno de QA efímero que se crea, se usa y se destruye en cada ejecución. Incluye la aplicación de prueba (un formulario de registro en React con su backend en Node/Express), las pruebas automatizadas y la infraestructura como código.

El ciclo completo es siempre el mismo:

1. **Aprovisionamiento.** Terraform crea los recursos en Azure con nombres únicos: Resource Group, App Service Linux, Application Insights y un Storage para publicar los informes.
2. **Configuración y despliegue.** Se compila la app, se despliega en App Service y se verifica su salud con un smoke test.
3. **Ejecución de pruebas.** Suite BDD escrita en Gherkin con Playwright, en dos niveles: API y UI. Los datos de prueba se generan con faker en cada corrida.
4. **Limpieza.** `terraform destroy` siempre, aunque las pruebas fallen. El entorno vive minutos y el coste residual es cero.

Algunas decisiones clave: los mensajes de validación del frontend y del backend son idénticos y las pruebas los usan como contrato; los localizadores viven solo en el Page Object (`data-testid`); los informes se generan en tres formatos (HTML de Playwright, JUnit para Azure DevOps y el HTML publicado en el Storage del propio entorno); los entornos llevan tags `CreatedAt`/`ExpiresAt` para gobernanza de costes.

## Qué hay en el repositorio

```
├── app/
│   ├── backend/    API Express de registro de usuarios; también sirve el frontend compilado
│   └── frontend/   Formulario en React y pruebas unitarias con Vitest
├── infra/          Terraform del entorno efímero
├── tests/          Suite BDD: features Gherkin (UI y API), pasos, Page Object y datos faker
├── scripts/        provision, deploy, run-tests, cleanup y demo-local
└── pipelines/      azure-pipelines.yml con las 4 etapas del ciclo
```

## Ejecutar en local

Requisitos: Node.js 20 o superior y Git (incluye Git Bash en Windows).

En Git Bash:

```bash
./scripts/demo-local.sh
```

En PowerShell:

```powershell
.\scripts\demo-local.ps1
```

Para ver el recorrido de las pruebas en el navegador (como con Cypress open), añade `--headed`; con `--ui` se abre el modo UI interactivo de Playwright. Cualquier otro argumento se pasa a `playwright test`:

```bash
./scripts/demo-local.sh --headed                                  # navegador visible
./scripts/demo-local.sh --ui                                      # modo UI interactivo
./scripts/demo-local.sh --headed features/ui/user-registration.feature
```

> Si PowerShell muestra "la ejecución de scripts está deshabilitada en este sistema" (afecta a `demo-local.ps1`, `npx` y `npm`), lanza los comandos con `powershell -ExecutionPolicy Bypass -File .\scripts\demo-local.ps1`, usa las variantes `.cmd` (`npx.cmd …`, `npm.cmd …`) o habilita los scripts locales solo para tu usuario con `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`.

El script instala dependencias, pasa las pruebas unitarias, compila el frontend, arranca la aplicación en http://localhost:3000, ejecuta la suite BDD completa y para el servidor al terminar.

Para ver el informe HTML (el separador `;` funciona igual en PowerShell que en Git Bash):

```bash
cd tests; npx playwright show-report reports/html
```

## Ejecutar en Azure

Necesitas `az login` y Terraform en el PATH. Crea el entorno con el nombre que quieras: cada nombre genera recursos únicos, así que puedes tener varios en paralelo.

```bash
./scripts/provision.sh qa-manual-1   # crea los recursos y escribe infra/terraform-outputs.json
./scripts/deploy.sh                  # build + despliegue + smoke test de /api/health
./scripts/run-tests.sh               # la misma suite, ahora contra la URL de Azure
./scripts/cleanup.sh qa-manual-1     # destruye el entorno
```

Si prefieres CI, `pipelines/azure-pipelines.yml` hace el ciclo completo (necesita una service connection de Azure llamada `qa-demo-azure`). Cada build levanta su propio entorno `qa-build-<id>`, publica los resultados en la pestaña Tests, deja el informe HTML como artefacto y destruye el entorno al acabar.
