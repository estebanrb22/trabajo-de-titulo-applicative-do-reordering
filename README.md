# trabajo-de-titulo-applicative-do-reordering
Trabajo de Titulo del Departamento de Ciencias de la Computacion (DCC) de la Universidad de Chile. Basado en el paper de Marlow, S., Peyton Jones S., Kmett E. y Mokhov A. "Desugaring Haskell's do-notation into applicative operations" (Proceedings of the 9th International Symposium on Haskell, 2016).

## Artefactos principales de la memoria

Los parches de este repositorio son los artefactos principales de aporte para la memoria. En particular, los cambios se mantienen como archivos de parche en `patches/` para su trazabilidad, aplicacion y evaluacion reproducible.

## Uso del Dev Container

Este repositorio incluye una configuracion de desarrollo en `.devcontainer/` para tener un entorno reproducible con GHC y herramientas de Haskell.

### Requisitos

- Docker instalado y en ejecucion.
- Visual Studio Code con la extension **Dev Containers** (recomendado).

### Levantar el entorno

1. Abre este repositorio en VS Code.
2. Ejecuta `Dev Containers: Reopen in Container` desde la paleta de comandos.
3. Espera a que termine el build del contenedor y la validacion inicial.

## Flujo recomendado con Makefile

Con el contenedor ya abierto, puedes ejecutar el flujo reproducible paso a paso con:

```bash
make verify-toolchain
make setup-ghc-build
make patches
make build
make test
```

Tambien existe un comando compacto para ejecutar el flujo completo:

```bash
make reproduce
```

## Referencia completa de comandos del Makefile

### Comandos generales

- `make help`: muestra ayuda y comandos disponibles.
- `make verify-toolchain`: verifica que la toolchain del contenedor este disponible.
- `make reproduce`: ejecuta el flujo reproducible completo (`verify-toolchain`, `setup-ghc-build`, `patches`, `build`, `test`).

### Preparacion de submodulo GHC

- `make add-submodule`: agrega o reutiliza `vendor/ghc` y lo fija al commit objetivo.
- `make init-submodule-recursive`: inicializa submodulos anidados de GHC (necesario para `./boot`).
- `make verify-submodule`: verifica que `vendor/ghc` este en el commit esperado.
- `make setup-ghc-build`: corre `add-submodule`, `init-submodule-recursive` y `verify-submodule`.

### Parches, build y pruebas

- `make patches`: aplica parches desde `patches/*.patch`.
- `make build`: ejecuta el proceso de completo de build de GHC (`boot, configure, hadrian/build`).
- `make test`: ejecuta pruebas y validaciones.
- `make ghc-quick`: compila GHC modificado con Hadrian (`--flavour=quick`, `stage2:exe:ghc-bin`).

### Docker y shell

- `make start-docker`: inicia el contenedor de desarrollo (`ghc-dev-container`).
- `make shell`: abre una shell dentro del contenedor; si no esta corriendo, lo inicia.

### Utilidades de experimentos y logs

- `make restart-ghc`: reinicia el submodulo `vendor/ghc` al commit objetivo (usa `git reset --hard` y `git clean -ffd` dentro de `vendor/ghc`).
- `make cabal-project <project-dir>`: crea un proyecto Cabal Maybe bajo `experiments/` con un ejemplo usando `CD.do`; si `<project-dir>` incluye `experiments/`, el nombre Cabal se deriva desde lo posterior a esa carpeta, convierte `n-defs` en `ndefs`, reemplaza separadores por `-` y antepone `n` a componentes numericos sueltos.
- `make cabal-prob-project <project-dir>`: crea un proyecto Cabal probabilistico bajo `experiments/` con `probability ^>=0.2.9.1` y un ejemplo de dos dados usando `CD.do`, usando la misma derivacion de nombre Cabal que `cabal-project`.
- `make cabal-renamer-logs <project-dir> <output-log-file>`: extrae el bloque `do ... return`, ejecuta `cabal build` y guarda trazas del renamer.
- `make renamer-logs <input-file> <output-log-file> [-concat]`: compila con `./vendor/ghc/_build/stage1/bin/ghc -ddump-rn-trace -XApplicativeDo -fno-code` y guarda el arbol final de `rearrangeForADo`.
- `make semantic-validation-reorder <input-file> <output-dir>`: compila la permutacion optima y cada candidato generado por GHC, ejecuta los binarios y compara outputs/codigos de salida.
