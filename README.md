# trabajo-de-titulo-applicative-do-reordering
Trabajo de Titulo del Departamento de Ciencias de la Computación (DCC) de la Universidad de Chile. Basado en el paper de Marlow, S., Peyton Jones S., Kmett E. y Mokhov A. "Desugaring Haskell’s do-notation into applicative operations" Proceedings of the 9th International Symposium on Haskell. 2016.  

## Artefactos principales de la memoria

Los parches de este repositorio serán los artefactos principales de aporte para la memoria. En particular, los cambios se mantendrán como archivos de parche en `patches/` para su trazabilidad, aplicación y evaluación reproducible.

## Seteo del submódulo GHC

La lógica de preparación y validación del submódulo GHC está en `scripts/setup-ghc/`.

Desde la raíz del repositorio, ejecuta en este orden:

1. `bash scripts/setup-ghc/add_ghc_submodule.sh`
2. `bash scripts/setup-ghc/init_submodules.sh`
3. `bash scripts/setup-ghc/verify_ghc_commit.sh`

Si prefieres Makefile, estos pasos equivalen a:

```bash
make add-submodule
make init-submodule
make verify-submodule
```

Atajo equivalente:

```bash
make setup-ghc-submodule
```

## Uso del Dev Container

Este repositorio incluye una configuración de desarrollo en `.devcontainer/` para tener un entorno reproducible con GHC y herramientas de Haskell.

### Requisitos

- Docker instalado y en ejecución.
- Visual Studio Code con la extensión **Dev Containers** (recomendado).

### Levantar el entorno

1. Abre este repositorio en VS Code.
2. Ejecuta `Dev Containers: Reopen in Container` desde la paleta de comandos.
3. Espera a que termine el build del contenedor y la validación inicial.

### Comando para entrar por consola al contenedor

Con el contenedor en ejecución, desde una terminal del host usa:

```bash
docker exec -it ghc-dev-container bash
```

## Reproducibilidad con Makefile

Con el contenedor ya abierto, puedes ejecutar el flujo reproducible paso a paso con:

```bash
make verify-toolchain
make add-submodule
make init-submodule
make verify-submodule
make patches
make build
make test
```

Tambien existe un comando compacto para ejecutar todo el flujo:

```bash
make reproduce
```
