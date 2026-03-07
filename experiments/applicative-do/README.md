# ApplicativeDo demo (tesis)

Este directorio contiene un experimento compacto pero representativo para
estudiar la extension `ApplicativeDo` usando el GHC del repo.

## Diseno del directorio

- `src/Main.hs`: programa con varios bloques `do` que ejercitan:
  - segmentos independientes (applicative puro),
  - dependencias (caida a bind),
  - `BodyStmt` (sentencia sin `<-`),
  - patrones estrictos y refutables,
  - bloque anidado,
  - caso que requiere `join`.
- `run.sh`: script para compilar/ejecutar el ejemplo.
- `build/`: artefactos locales (ignorado por git).
- `src/Main.dump-*`: dumps de compilacion cuando se activan flags.

## Como usar el submodulo `vendor/ghc`

`vendor/ghc` es el codigo fuente del compilador. Para usarlo para compilar
`src/Main.hs`, necesitas un binario de GHC construido desde ese submodulo.

### Paso 1: preparar submodulo

Desde la raiz del repo:

```bash
make setup-ghc-build
```

`make setup-ghc-build` inicializa `vendor/ghc`, submodulos anidados necesarios
para `./boot`, y verifica el commit pinneado.

### Paso 2: construir GHC dentro de `vendor/ghc`

Desde la raiz del repo:

```bash
cd vendor/ghc
./boot
./configure
./hadrian/build -j"$(nproc)" --flavour=devel2
cd ../..
```

Nota: este paso puede tardar bastante. Al finalizar, deberias ver los siguientes binarios en las rutas:

- `vendor/ghc/_build/stage1/bin/ghc`
- `vendor/ghc/_build/stage2/bin/ghc`

### Paso 3: compilar y ejecutar el ejemplo

Opcion recomendada (autodeteccion):

```bash
bash experiments/applicative-do/run.sh
```

Si quieres forzar un binario concreto del submodulo:

```bash
GHC_BIN=vendor/ghc/_build/stage1/bin/ghc bash experiments/applicative-do/run.sh
```

`run.sh` resuelve rutas relativas de `GHC_BIN` desde la raiz del repo,
autodetecta rutas comunes dentro de `vendor/ghc` y, si no encuentra ninguna,
intenta usar `ghc` del `PATH`.

## Salida esperada

```text
ApplicativeDo compact+advanced demo
pureApplicativeExample = Just 70
mixedDependencyExample = Just 131
bodyStmtExample = Just 77
strictPatternExample = Just 16
nestedExample = Just 22
refutablePatternExample = Just 42
joinExample = Just 17
combinedReport = Just Report {... grandTotal = 375}
```

## Generar documentos de compilacion

### Solo desugaring (compacto)

```bash
DUMP_DS=1 bash experiments/applicative-do/run.sh
```

Genera:

- `experiments/applicative-do/src/Main.dump-ds`

### Pipeline de `ApplicativeDo` (renamer + typechecker + desugar)

```bash
DUMP_PIPELINE=1 bash experiments/applicative-do/run.sh
```

Genera:

- `experiments/applicative-do/src/Main.dump-rn`
- `experiments/applicative-do/src/Main.dump-tc`
- `experiments/applicative-do/src/Main.dump-ds`

### Core simplificado (opcional)

```bash
DUMP_SIMPL=1 bash experiments/applicative-do/run.sh
```

Genera:

- `experiments/applicative-do/src/Main.dump-simpl`

### Flags extra de GHC (opcional)

```bash
EXTRA_GHC_FLAGS="-ddump-deriv" bash experiments/applicative-do/run.sh
```

`run.sh` tambien escribe un manifiesto con los dumps generados en:

- `experiments/applicative-do/build/dump-manifest.txt`
