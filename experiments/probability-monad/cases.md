# Casos sintéticos para la mónada de probabilidades

Este archivo documenta la decisión inicial de casos sintéticos para validar la preservación semántica de las permutaciones generadas por la extensión experimental de `ApplicativeDo` sobre la mónada probabilística `Dist.T Rational` del paquete `probability`.

El objetivo del corpus es cubrir dos niveles de fenómenos:

- Fenómenos estructurales del renamer y del grafo de precedencia RAW, reutilizables desde el corpus de `Maybe`.
- Fenómenos específicos de distribuciones probabilísticas finitas, como pesos, soportes dependientes, normalización de resultados duplicados y condicionamiento.

## Decisión de salida canónica

Todos los programas probabilísticos deben imprimir una distribución normalizada por defecto:

```haskell
main :: IO ()
main = print (Dist.norm example)
```

`Dist.norm` agrupa resultados iguales y suma sus probabilidades. Esto evita comparar representaciones internas distintas de una misma distribución durante la validación semántica, ya que el pipeline compara `stdout` byte a byte entre el programa original, el programa con `ApplicativeDo`, el candidato óptimo y cada permutación generada.

La excepción sería un caso cuyo objetivo sea estudiar explícitamente la representación interna sin normalizar. Ese tipo de caso no forma parte del corpus inicial.

## Organización

Los programas fuente se organizan por familia conceptual, caso específico y variante interna:

```text
experiments/probability-monad/cases/<familia>/<caso>/<variante>/
  main.hs
  cabal.project
  <package>.cabal
```

La variante normalmente corresponde a la cantidad de statements del bloque `do`, por ejemplo `02/`, `03/`, `04/` o `05/`. Si se necesitan varias variantes con la misma cantidad de statements, se usa un sufijo descriptivo:

```text
experiments/probability-monad/cases/dependency-shapes/chain-no-reorder/04-minimum/
experiments/probability-monad/cases/probability-distributions/duplicate-outcomes-sum/02/
```

Los resultados del pipeline de validación se guardan espejando la ruta del caso bajo `tests/probability-monad`:

```text
tests/probability-monad/cases/<familia>/<caso>/<variante>/
  summary.log
  semantic-validation.log
  graph.log
  logs/
  results/
  bin/
  cabal-build/
```

## Validación

Los casos probabilísticos deben validarse con el backend Cabal, porque dependen del paquete externo `probability`:

```text
make test-cabal experiments/probability-monad/cases/<familia>/<caso>/<variante>
```

Evitar el backend GHC directo para estos casos, salvo que el programa no tenga dependencias externas. Todos los programas deben mantener un único bloque experimental `CD.do`/`CD.return` para que los scripts de validación puedan extraerlo correctamente.

## Convenciones para programas probabilísticos

- Usar `Dist.T Rational` como mónada objetivo.
- Mantener `instance CD.CommutativeMonad (Dist.T Rational)` en casos con `CD.do`.
- Usar `Dist.certainly` cuando el caso solo prueba una forma de grafo.
- Usar soportes pequeños con `Dist.uniform`, `Dist.choose`, `Dist.relative` o `Dist.fromFreqs` cuando el caso prueba comportamiento probabilístico real.
- Evitar muestreo aleatorio, simulación o IO dentro del ejemplo probabilístico.
- Retornar valores con instancias `Ord` y `Show`, porque `Dist.norm` y `print` las necesitan.
- Evitar `Dist.decons` en `main`, porque expone orden interno y duplicados no canónicos.
- Evitar patrones refutables estrictos que requieran `MonadFail`, salvo que se esté documentando una semántica probabilística explícita para ese fallo.

## Tabla de casos

| Familia | Caso | Variantes iniciales | Qué prueba |
|---|---|---|---|
| `dependency-shapes` | `no-deps` | `03/`, `04/` | Grafo vacío; deberían generarse todas las permutaciones topológicas. |
| `dependency-shapes` | `chain-no-reorder` | `04-minimum/`, `04-super-graph/`, `06-minimum/`, `06-super-graph/` | Grafo lineal donde solo debe ser válida la permutación original. |
| `dependency-shapes` | `two-chains` | `04-interpolated/`, `08-interpolated/`, `08-super-graph/`, `08-reorder-improves-ado/` | Dos cadenas independientes con interleavings válidos. |
| `dependency-shapes` | `diamond` | `04-minimum/`, `06-minimum/` | Dependencia compartida con dos ramas que convergen. |
| `dependency-shapes` | `fanout` | `05/` | Un binder probabilístico usado por varios statements posteriores. |
| `dependency-shapes` | `fanin` | `05/` | Varios binders probabilísticos usados por un statement posterior. |
| `probability-distributions` | `weighted-independent` | `03/` | Distribuciones independientes con pesos no uniformes. |
| `probability-distributions` | `duplicate-outcomes-sum` | `02/` | Normalización de resultados duplicados, como en la suma de dados. |
| `probability-distributions` | `dependent-support` | `03/` | El soporte de una distribución depende de un valor generado antes. |
| `probability-distributions` | `dependent-weights` | `03/` | Los pesos de una distribución posterior dependen de un valor generado antes. |
| `probability-distributions` | `duplicate-source-outcomes` | `02/` | Una distribución fuente contiene resultados repetidos antes de la normalización final. |
| `probability-distributions` | `choose-independent` | `03/` | Uso de `Dist.choose` en distribuciones independientes. |
| `probability-distributions` | `choose-dependent` | `03/` | Uso de `Dist.choose` con pesos que dependen de un binder previo. |
| `probability-distributions` | `from-freqs` | `03/` | Construcción de distribuciones desde frecuencias normalizadas con `Dist.fromFreqs`. |
| `body-stmts` | `independent` | `03/` | `BodyStmt` sin binder y sin variables locales leídas. |
| `body-stmts` | `dependent` | `03/` | `BodyStmt` sin binder, pero que lee un binder probabilístico previo. |
| `probability-conditioning` | `impossible-independent` | `03/` | Distribución imposible independiente modelada explícitamente con `Dist.Cons []`. |
| `probability-conditioning` | `filter-bind` | `03/` | Condicionamiento explícito con `Dist.filter` sobre una distribución finita. |
| `binders` | `tuple-pattern` | `03-binary/`, `03-wildcard/`, `05-ternary/` | Patrones de tupla que definen múltiples binders desde un resultado probabilístico. |
| `binders` | `list-pattern` | `03-singleton/`, `03-two-elements/`, `03-wildcard/`, `04-cons-tail/` | Patrones de lista adaptados con semántica probabilística explícita. |
| `binders` | `nested-pattern` | `04/` | Extracción recursiva de binders desde patrones anidados. |
| `binders` | `wildcard-as-pattern` | `04/` | Wildcards, as-patterns y binders simultáneos en un resultado probabilístico. |
| `binders` | `lazy-pattern` | `03/` | Patrón lazy sobre una distribución probabilística. |
| `binders` | `lazy-pattern-unused` | `03/` | Patrón lazy potencialmente refutable cuyos binders no se demandan. |
| `let-statements` | `let-independent` | `03/` | `let` independiente que no debería introducir dependencias RAW falsas. |
| `let-statements` | `let-depends-on-bind` | `03/` | `let` que lee un binder probabilístico previo. |
| `let-statements` | `bind-depends-on-let` | `03/` | `BindStmt` probabilístico que lee una variable definida por `let`. |
| `let-statements` | `let-shadowing` | `04/` | Shadowing introducido por `let` dentro del bloque probabilístico. |
| `shadowing` | `rebind-same-name` | `03/` | Reutilización del mismo nombre fuente con `Name`s renombrados distintos. |
| `shadowing` | `read-before-rebind` | `03/` | Lectura del binder antiguo antes de reutilizar el mismo nombre fuente. |
| `shadowing` | `read-after-rebind` | `03/` | Lectura del binder nuevo después de reutilizar el mismo nombre fuente. |
| `shadowing` | `return-uses-rebound-name` | `03/` | El `CD.return` usa el binder sombreado más reciente. |
| `cost-selection` | `original-not-minimal` | `04/` | El orden original no produce el menor costo de `ApplicativeDo`. |
| `cost-selection` | `all-same-cost` | `04/` | Todas las permutaciones válidas tienen el mismo costo. |
| `cost-selection` | `unique-minimum` | `05/` | Existe una única permutación de costo mínimo. |
| `cost-selection` | `many-minimums` | `06/` | Varias permutaciones empatan en costo mínimo. |
| `controls` | `plain-do-no-marker` | `04/` | Control negativo: sin `CD.do` no debe activarse el reordenamiento conmutativo. |
| `controls` | `qualified-do-no-marker` | `04/` | Control negativo: importar `CD` e instanciar la clase no basta si el bloque usa `do` normal. |
| `controls` | `qualified-do-marker` | `04/` | Control positivo: con `CD.do` debe activarse el reordenamiento conmutativo. |

## Familias reutilizables desde Maybe

Las siguientes familias prueban principalmente el renamer, la recolección de binders, las variables libres y el grafo de precedencia RAW. Por eso se pueden adaptar desde el corpus de `Maybe` reemplazando `Just` por `Dist.certainly` o por distribuciones finitas pequeñas:

```text
dependency-shapes
binders
let-statements
body-stmts
shadowing
cost-selection
controls
```

La adaptación debe conservar la forma del grafo. Si se usa una distribución no degenerada para hacer el caso más probabilístico, esa distribución no debe introducir complejidad innecesaria ni aumentar demasiado el tamaño del soporte observable.

## Familias específicas de probabilidades

La familia `probability-distributions` cubre fenómenos propios de distribuciones finitas:

- `weighted-independent`: comprueba que el reordenamiento preserva productos de probabilidades con pesos no uniformes.
- `duplicate-outcomes-sum`: comprueba que distintas ramas pueden producir el mismo resultado y que `Dist.norm` entrega una salida canónica.
- `dependent-support`: comprueba dependencias RAW donde el soporte de una distribución posterior depende de un resultado anterior.
- `dependent-weights`: comprueba dependencias RAW donde el soporte posterior se conserva, pero sus pesos cambian según un resultado anterior.
- `duplicate-source-outcomes`: comprueba que una distribución fuente con resultados repetidos se conserva bajo reordenamiento y queda canónica con `Dist.norm`.
- `choose-independent`: comprueba el constructor binario `Dist.choose` en statements independientes.
- `choose-dependent`: comprueba `Dist.choose` cuando los pesos dependen de un binder previo.
- `from-freqs`: comprueba construcción por frecuencias con `Dist.fromFreqs`.

La familia `probability-conditioning` reemplaza los casos de fallo de `Maybe` por observaciones probabilísticas:

- `impossible-independent`: una distribución imposible independiente debe preservar semántica bajo permutación, pero debe documentarse porque puede producir salida vacía.
- `filter-bind`: el filtrado se hace como parte de un `BindStmt` y debe conservar al menos una rama para evitar `fromFreqs []`.
- `observe-dependent` se descarta del corpus implementado porque su lectura de binder como `BodyStmt` ya queda cubierta por `body-stmts/dependent`, y su efecto de eliminación de ramas queda mejor representado por `filter-bind`.

## Casos excluidos o adaptados

Los casos `maybe-failure` no se copian directamente porque dependen de `Nothing`, `MonadFail Maybe` y fallos de patrones. En `Dist.T Rational`, el fallo debe modelarse con operaciones de distribución, observación o soporte imposible.

Los patrones de lista estrictos sí se consideran dentro de `binders/list-pattern`, pero no como una conversión mecánica desde `Maybe`. Cada variante debe definir una semántica probabilística explícita y mantener soportes pequeños para que `Dist.norm` entregue una salida canónica comparable.
