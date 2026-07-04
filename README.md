# trabajo-de-titulo-applicative-do-reordering
Trabajo de Título del Departamento de Ciencias de la Computación (DCC) de la Universidad de Chile. Basado en el paper de Marlow, S., Peyton Jones S., Kmett E. y Mokhov A. "Desugaring Haskell's do-notation into applicative operations" (Proceedings of the 9th International Symposium on Haskell, 2016).

## Artefactos principales de la memoria

Los parches de este repositorio son los artefactos principales de aporte para la memoria. En particular, los cambios se mantienen como archivos de parche en `patches/` para su trazabilidad, aplicación y evaluación reproducible.

## Objetivo de la memoria

Esta memoria estudia una extensión experimental de `ApplicativeDo` en GHC para explorar reordenamientos semanticamente válidos de statements en una `do-notation` cuando la mónada usada es conmutativa (permite el reordenamiento de statements manteniendo la semántica del programa).

La extensión modifica el Renamer de GHC para que, al detectar bloques marcados con `QualifiedDo` mediante `CD.do` y `CD.return`, construya un grafo de precedencia entre statements usando dependencias RAW (Read after Write). A partir de ese grafo se enumeran permutaciones topológicas válidas, se construye un plan de ejecución ingresando cada permutación candidata al algoritmo presente en `ApplicativeDo` y se selecciona la mejor segun su costo (sistema de costo simple).

La activacion experimental se realiza usando el modulo `Control.Monad.CommutativeDo` que fue agregado al compilador GHC por esta memoria, normalmente es importado como `CD`. Un bloque `CD.do` y terminando en `CD.return` indica que el programador declara que la mónada puede tratarse como conmutativa para efectos de reordenamiento.

## Uso del Dev Container

Este repositorio incluye una configuración de desarrollo en `.devcontainer/` para tener un entorno reproducible con GHC y herramientas de Haskell.

### Requisitos

- Docker instalado y en ejecución.
- Visual Studio Code con la extensión **Dev Containers** (recomendado).

### Levantar el entorno

1. Abre este repositorio en VS Code.
2. Ejecuta `Dev Containers: Reopen in Container` desde la paleta de comandos.
3. Espera a que termine el build del contenedor y la validación inicial.

## Experimentos y resultados

Los programas experimentales viven bajo `experiments/`. En particular, el corpus sintético de `Maybe` se organiza por familia, caso y variante:

```text
experiments/maybe-monad/cases/<familia>/<caso>/<variante>/
```

Los resultados generados por el pipeline de validación se guardan espejando esa ruta bajo `tests/`:

```text
tests/maybe-monad/cases/<familia>/<caso>/<variante>/
```

### Estructura de resultados en tests/

- `semantic-validation.log`: resumen operativo de la validación. Registra compilaciones, ejecuciones, outputs capturados, códigos de salida y la comparación final. Un caso exitoso termina con `RESULT: OK`.
- `summary.log`: resumen numérico del renamer para `ApplicativeDo`, incluyendo costo original, costo con `ApplicativeDo`, costo mínimo con reordenamiento, permutaciones generadas y cantidad de permutaciones de costo mínimo.
- `logs/graph.log`: vista legible del grafo de precedencia. Incluye el programa original, la representación interna `ppsfa`, la lista de adyacencia del grafo y las dependencias RAW agrupadas por binder.
- `logs/optimal-reorder.log`: log del candidato elegido automáticamente por el pipeline. Contiene el bloque de la `do-notation` reordenada, la traza del renamer, el `StmtTree` generado por la extensión `ApplicativeDo`, el costo y el plan de ejecución.
- `logs/original_ado.log`: muestra la variante compilada con `ApplicativeDo` normal, sin el marcador conmutativo `CD.do`.
- `logs/permutation_i.log`: muestra la permutación candidata `i`, forzada con `-fado-reorder-candidate-n=i`.
- `logs/raw.log`: traza cruda del renamer. Es útil para depuración fina, pero `graph.log` es la vista recomendada para leer el grafo.
- `results/`: outputs (`*.run.log`) y códigos de salida (`*.exit`) de cada binario ejecutado.
- `bin/`: binarios compilados por el pipeline.
- `cabal-build/`: directorios internos de build cuando la validación se ejecuta vía Cabal.

En `logs/graph.log`, la lista de adyacencia representa el grafo de precedencia por índice de statement:

```text
-- Precedence graph adjacency list
1 -> {2, 3}
2 -> {}
3 -> {}

-- Precedence graph RAW dependencies grouped by binder
x1: 1 -> {2, 3}
```

Si el grafo no tiene aristas, se muestra explícitamente:

```text
<no precedence edges: 0 RAW dependencies, all statements are independent>
```

Si no se cumplen las condiciones para ejecutar el reordenamiento conmutativo, por ejemplo porque el bloque no usa `CD.do`, se muestra:

```text
<reordering not executed: commutative-do conditions were not met>
```

En `logs/optimal-reorder.log`, la seccion `-- Execution plan` resume el plan elegido: `|` indica composicion applicativa y `;` indica dependencia secuencial.

## Flujo recomendado con Makefile

Con el contenedor ya abierto, puedes ejecutar el flujo reproducible paso a paso con:

```bash
make verify-toolchain
make setup-ghc-build
make patches
make build
make test
```

También existe un comando compacto para ejecutar el flujo completo:

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

### Utilidades de experimentos

- `make restart-ghc`: reinicia el submodulo `vendor/ghc` al commit objetivo (usa `git reset --hard` y `git clean -ffd` dentro de `vendor/ghc`).
- `make cabal-project <project-dir>`: crea un proyecto Cabal Maybe bajo `experiments/` con un ejemplo usando `CD.do`.
- `make cabal-prob-project <project-dir>`: crea un proyecto Cabal probabilístico bajo `experiments/` con `probability ^>=0.2.9.1` y un ejemplo de dos dados usando `CD.do`.

### Logs del renamer

- `make ghc-raw-logs <input-file> <output-log-file> [candidate-n]`: compila con el GHC modificado, guarda la salida completa de `-ddump-rn-trace` y acepta opcionalmente `candidate-n`.

### Validación semántica

- `make test-ghc <experiments/.../main.hs>`: wrapper recomendado para programas compilados directamente con GHC. Calcula el directorio de salida bajo `tests/...` reemplazando el prefijo `experiments/` y quitando el sufijo `/main.hs`.
- `make test-cabal <experiments/.../project-dir>`: wrapper recomendado para proyectos Cabal. Calcula el directorio de salida bajo `tests/...` reemplazando el prefijo `experiments/`.
- `make semantic-validation-reorder-ghc <input-file> <output-dir>`: ejecuta la validación semántica usando el GHC modificado directamente sobre un archivo `main.hs`.
- `make semantic-validation-reorder-cabal <project-dir> <output-dir>`: ejecuta la validación semántica usando Cabal, apropiado para proyectos con dependencias externas.
