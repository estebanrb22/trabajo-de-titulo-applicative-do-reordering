# Casos sinteticos para Maybe

Este archivo documenta la decision final de casos sinteticos para validar la preservacion semantica de las permutaciones generadas por la extension experimental de `ApplicativeDo` sobre la monada `Maybe`.

El objetivo del corpus es cubrir, de forma representativa, los fenomenos que afectan al grafo de precedencia de statements, la recoleccion de binders, la seleccion por costo y la semantica observable de `Maybe` ante fallos.

## Organizacion

Los programas fuente se organizan por familia conceptual, caso especifico y variante interna:

```text
experiments/maybe-monad/cases/<familia>/<caso>/<variante>/
  main.hs
  cabal.project
  <package>.cabal
```

La variante normalmente corresponde a la cantidad de statements del bloque `do`, por ejemplo `03/`, `04/` o `05/`. Si se necesitan varias variantes con la misma cantidad de statements, se usa un sufijo descriptivo:

```text
experiments/maybe-monad/cases/binders/tuple-pattern/03-basic/
experiments/maybe-monad/cases/binders/tuple-pattern/03-failing/
```

Los resultados del pipeline de validacion se guardan espejando la ruta del caso bajo `tests/maybe-mondad`:

```text
tests/maybe-mondad/cases/<familia>/<caso>/<variante>/semantic-validation/
  summary.log
  semantic-validation.log
  logs/
  results/
  bin/
  cabal-build/
```

## Tabla de casos

| Familia | Caso | Variantes iniciales | Que prueba |
|---|---|---|---|
| `smoke` | `independent` | `02/` | Caso minimo independiente para validar que el pipeline funciona. |
| `dependency-shapes` | `chain-no-reorder` | `03/`, `05/` | Grafo lineal donde solo debe ser valida la permutacion original. |
| `dependency-shapes` | `no-deps` | `03/`, `04/` | Grafo vacio; deberian generarse `n!` permutaciones. |
| `dependency-shapes` | `two-chains` | `04/`, `06/` | Dos cadenas independientes con interleavings validos. |
| `dependency-shapes` | `diamond` | `05/` | Dependencia compartida con ramas que convergen. |
| `dependency-shapes` | `fanout` | `05/` | Un binder usado por varios statements posteriores. |
| `dependency-shapes` | `fanin` | `05/` | Varios binders usados por un statement posterior. |
| `binders` | `tuple-pattern` | `03/`, `05/` | Patrones que definen multiples variables. |
| `binders` | `list-pattern` | `03/` | Patrones de listas, estrictos y refutables. |
| `binders` | `nested-pattern` | `04/` | Extraccion recursiva de binders en patrones anidados. |
| `binders` | `wildcard-as-pattern` | `04/` | Wildcards, as-patterns y binders simultaneos. |
| `binders` | `lazy-pattern` | `03/` | Patron lazy cuyos binders si se usan despues. |
| `binders` | `lazy-pattern-unused` | `03/` | Patron lazy potencialmente fallido, pero cuyos binders no se demandan. |
| `let-statements` | `let-independent` | `03/` | `let` que no deberia introducir dependencias falsas. |
| `let-statements` | `let-depends-on-bind` | `04/` | `let` que lee un binder monadico previo. |
| `let-statements` | `bind-depends-on-let` | `04/` | Statement monadico que lee una variable definida por `let`. |
| `let-statements` | `let-shadowing` | `04/` | Shadowing introducido por `let`. |
| `body-stmts` | `independent` | `03/`, `04/` | `BodyStmt` sin binder, sin fallo y sin variables locales leidas. |
| `body-stmts` | `dependent` | `03/`, `04/` | `BodyStmt` sin binder, pero que lee una variable definida antes. |
| `maybe-failure` | `nothing-independent` | `03/` | Fallo independiente con `Nothing`. |
| `maybe-failure` | `nothing-after-dependency` | `04/` | Fallo despues de una dependencia real. |
| `maybe-failure` | `pattern-fail-tuple` | `03/` | Fallo por patron de tupla refutable. |
| `maybe-failure` | `pattern-fail-list` | `03/` | Fallo por patron de lista refutable. |
| `maybe-failure` | `guard-body-stmt` | `04/` | `BodyStmt` que puede fallar y lee variables locales. |
| `shadowing` | `rebind-same-name` | `03/` | Reutilizacion del mismo nombre fuente en distintos binders. |
| `shadowing` | `read-before-rebind` | `04/` | Lectura del binder antiguo antes de un rebinding. |
| `shadowing` | `return-uses-rebound-name` | `04/` | El `return` usa el binder sombreado mas reciente. |
| `cost-selection` | `original-not-minimal` | `04/` | El orden original no produce el menor costo. |
| `cost-selection` | `all-same-cost` | `04/` | Todas las permutaciones tienen el mismo costo. |
| `cost-selection` | `unique-minimum` | `05/` | Existe una unica permutacion de costo minimo. |
| `cost-selection` | `many-minimums` | `06/` | Varias permutaciones empatan en costo minimo. |
| `controls` | `plain-do-no-marker` | `04/` | Control negativo: sin marcador conmutativo no debe reordenar. |
| `controls` | `qualified-do-marker` | `04/` | Control positivo: con `CD.do` debe activar el reordenamiento. |

## Familias especificas de Maybe

La mayoria de las familias son conceptualmente reutilizables para otras monadas conmutativas, porque prueban propiedades del renamer y del grafo de precedencia:

```text
smoke
dependency-shapes
binders
let-statements
body-stmts
shadowing
cost-selection
controls
```

La familia `maybe-failure` es especifica de `Maybe`, ya que depende de `Nothing`, `MonadFail Maybe` y del comportamiento de fallo de patrones o guards. Para una monada de probabilidades, estos casos deberian adaptarse a la nocion disponible de fallo, evento imposible o condicionamiento.
