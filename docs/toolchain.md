# Cadena de herramientas y reproducibilidad

## Eleccion del SO base

Esta configuracion usa Ubuntu 22.04 LTS como imagen base.

Por que 22.04 LTS:
- Soporte de largo plazo y ecosistema de paquetes estable para cadenas de herramientas de compiladores.
- Superficie de compatibilidad mas conocida para compilar GHC desde codigo fuente con `libffi` y `libgmp`.
- Soporte amplio en CI/CD y comportamiento predecible para flujos de trabajo de memoria.

Compensacion frente a 24.04 LTS:
- 22.04 tiene versiones de paquetes mas antiguas.
- 24.04 ofrece paquetes mas nuevos, pero puede requerir mas validacion de compatibilidad para scripts de bootstrap/build de GHC.

## Dependencias del contenedor

El Dockerfile instala todas las dependencias requeridas:

- Herramientas base: `git`, `build-essential`, `curl`, `wget`, `ca-certificates`, `xz-utils`, `gzip`, `bzip2`, `unzip`, `tar`, `pkg-config`, `python3`, `perl`, `time`, `jq`, `diffutils`, `autoconf`, `automake`, `libtool`
- Librerias: `libgmp-dev`, `zlib1g-dev`, `libncurses-dev`, `libffi-dev`
- Soporte de ejecucion/herramientas: `locales`, `sudo`, `gnupg`, `dirmngr`

Cadena de herramientas de Haskell fijada en el contenedor:
- GHC `9.14.1`
- cabal-install `3.14.2.0`
- alex `3.5.4.0`
- happy `2.2`

Metodo de instalacion:
- `ghcup` instala y fija GHC + cabal.
- `cabal install` instala versiones pinneadas de alex + happy en `~/.local/bin`.
- `autoconf`/`automake` proveen `autoreconf`/`aclocal` para ejecutar `./boot` en `vendor/ghc`.

### Justificacion de las versiones fijadas

- **GHC `9.14.1`**
  - Se usa una version estable (no snapshot de desarrollo).
  - El arbol de GHC fijado en `vendor/ghc` exige, para bootstrap, **GHC 9.10 o superior** (`vendor/ghc/configure.ac`, `MinBootGhcVersion="9.10"`); `9.14.1` cumple ese requisito.
  - Es una version ampliamente disponible en `ghcup` para Ubuntu 22.04, lo que reduce friccion al reconstruir el entorno en distintas maquinas.

- **cabal-install `3.14.2.0`**
  - Se fija junto con `GHC 9.14.1` para mantener una pareja de herramientas coherente y estable dentro del contenedor.
  - Se utiliza para instalar `alex` y `happy` en versiones exactas; mantener `cabal-install` pinneado evita variaciones de comportamiento entre reconstrucciones.

- **alex `3.5.4.0`**
  - El arbol de GHC requiere **Alex >= 3.2.6 y < 4** (`vendor/ghc/m4/fptools_alex.m4`).
  - `3.5.4.0` esta por sobre el minimo y se fija para mantener reproducible la generacion de artefactos.

- **happy `2.2`**
  - El arbol de GHC requiere **Happy == 1.20.* o >= 2.0.2 y < 2.3** (`vendor/ghc/m4/fptools_happy.m4`).
  - `2.2` cumple ese rango y se fija para evitar deriva en salidas generadas del parser.

## Fijacion del digest de imagen Ubuntu

La imagen del Dev Container esta fijada actualmente a este digest exacto de Ubuntu:

`ubuntu:22.04@sha256:3ba65aa20f86a0fad9df2b2c259c613df006b2e6d0bfcc8a146afb8c525a9751`

En `.devcontainer/Dockerfile`, esto se expresa mediante:

- `ARG UBUNTU_VERSION=22.04`
- `ARG UBUNTU_DIGEST=3ba65aa20f86a0fad9df2b2c259c613df006b2e6d0bfcc8a146afb8c525a9751`
- `FROM ubuntu:${UBUNTU_VERSION}@sha256:${UBUNTU_DIGEST}`

Por que se tomo esta decision de reproducibilidad:

- Las etiquetas de Docker como `ubuntu:22.04` son mutables en el tiempo.
- Fijar por digest garantiza el mismo filesystem base entre hosts/CI y a lo largo del tiempo.
- Esto reduce la deriva del entorno al validar comportamiento del compilador, errores y rendimiento en experimentos de la memoria.

## Flujo reproducible de punta a punta

1. Reconstruye/abre el proyecto en Dev Container.
2. Ejecuta `make verify-toolchain` (tambien corre automaticamente via `postCreateCommand`).
3. Ejecuta `make add-submodule`.
4. Ejecuta `make init-submodule`.
5. Ejecuta `make verify-submodule`.
6. Ejecuta `make patches` (aplica `patches/*.patch` ya presentes; si no hay, lo reporta).
7. Ejecuta `make build`.
8. Ejecuta `make test`.

## Reproducibilidad con Makefile

Comando recomendado (flujo completo en una sola orden, dentro del contenedor):

```bash
make reproduce
```

Comandos utiles por bloque:

- `make verify-toolchain`: valida la toolchain del Dev Container.
- `make setup-ghc-build`: igual que el anterior, pero ademas inicializa submodulos anidados necesarios para `vendor/ghc/boot`.
