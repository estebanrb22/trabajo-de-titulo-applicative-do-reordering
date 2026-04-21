# trabajo-de-titulo-applicative-do-reordering
Trabajo de Titulo del Departamento de Ciencias de la Computación (DCC) de la Universidad de Chile. Basado en el paper de Marlow, S., Peyton Jones S., Kmett E. y Mokhov A. "Desugaring Haskell’s do-notation into applicative operations" Proceedings of the 9th International Symposium on Haskell. 2016.  

## Artefactos principales de la memoria

Los parches de este repositorio serán los artefactos principales de aporte para la memoria. En particular, los cambios se mantendrán como archivos de parche en `patches/` para su trazabilidad, aplicación y evaluación reproducible.

## Seteo del submódulo GHC

El repositorio contiene un archivo Makefile, así que para preparar e iniciar el submódulo de GHC, ejecutar:

```bash
make setup-ghc-submodule
```

El comando anterior realiza la tarea de añadir e iniciar de forma recursiva todos los submódulos de GHC, equivalente a esta
serie de comandos unitarios:

```bash
make add-submodule
make init-submodule
make verify-submodule
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

### Comando para entrar por consola al contenedor

Con el contenedor en ejecución, desde una terminal del host usa:

```bash
make shell
```
