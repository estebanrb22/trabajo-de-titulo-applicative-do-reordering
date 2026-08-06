# Estructura del informe final

Este documento registra la estructura acordada para el informe final de memoria. Su objetivo es mantener una guía macro y micro de escritura antes de desarrollar el contenido definitivo en LaTeX.

## Criterios generales

- Usar capítulos con títulos cortos: Introducción, Marco Teórico, Problema, Diseño de Solución, Implementación de la Solución, Validación, Resultados y Conclusión.
- No usar un capítulo independiente llamado ApplicativeDo en GHC, porque el detalle interno del compilador puede volver denso el informe. Ese contenido se distribuye entre Marco Teórico, Solución y anexos.
- Usar como ejemplo guía el modelo académico probabilístico de `experiments/main-example/main.hs`, porque presenta dependencias y planes de ejecución mediante una historia concreta del dominio de la memoria.
- Mantener el ejemplo guía como caso transversal del informe y distinguirlo de los corpus sintéticos usados para la evaluación agregada.
- Concentrar la validación en dos corpus sintéticos: uno estructural con `Maybe` y otro probabilístico con `Dist.T Rational`; mantener `IO` como control negativo auxiliar y no como un tercer corpus.
- Mencionar el modelo de costo uniforme como limitación actual y proponer su refinamiento como trabajo futuro.
- Usar **grafo de precedencia RAW** como término canónico para el grafo inducido por dependencias RAW locales entre statements. Reservar **dependencia RAW local** para la relación que origina una arista y usar **el grafo** solo como referencia anafórica; no emplear **grafo RAW**, **grafo de dependencias** ni **grafo de precedencia** como nombres alternativos.
- Conservar sin modificaciones los identificadores literales de la implementación, las trazas y las macros, como `StmtDepGraph`, `buildStmtsDependencyGraph` y `PrecedenceGraph`.

## Ejemplo guía

El ejemplo guía corresponde al caso:

```text
experiments/main-example/main.hs
```

Bloque principal:

```haskell
studentResults = CD.do
  preparation <- Dist.uniform [Low, High]
  quiz <- quizGiven preparation
  difficulty <- Dist.uniform [Easy, Hard]
  finalExam <- examGiven preparation difficulty
  CD.return (preparation, quiz, difficulty, finalExam)
```

Statements:

```text
s1 = preparation <- Dist.uniform [Low, High]
s2 = quiz <- quizGiven preparation
s3 = difficulty <- Dist.uniform [Easy, Hard]
s4 = finalExam <- examGiven preparation difficulty
```

Dependencias RAW:

```text
s1 -> s2
s1 -> s4
s3 -> s4
```

Grafo de precedencia RAW:

```text
s1 -----> s2
|
+------> s4
          ^
s3 -------+
```

Planes de ejecución:

```text
Secuencial:
s1 ; s2 ; s3 ; s4        costo 4

ApplicativeDo actual:
s1 ; (s2 | (s3 ; s4))    costo 3

ApplicativeDo + reorder:
(s1 | s3) ; (s2 | s4)    costo 2
```

Los resultados canónicos están en `tests/main-example`. `summary.log` confirma los costos `4 -> 3 -> 2`, cinco permutaciones y cuatro mínimos; `logs/optimal-reorder.log` registra la selección del candidato 1 con orden `[1,3,2,4]`; `semantic-validation.log` termina con `RESULT: OK` para el original, `ApplicativeDo`, el candidato óptimo y todas las permutaciones.

Este ejemplo permite explicar la mejora incremental desde el dominio probabilístico: primero se pasa de ejecución secuencial a `ApplicativeDo`, y luego el reordenamiento conmutativo permite exponer un plan de menor costo sin cambiar la distribución normalizada.

## Capítulos

| Capítulo | Archivo wrapper | Rol |
|---|---|---|
| Introducción | `secciones/intro.tex` | Contexto, problema y enfoque de solución, objetivos y contribuciones. |
| Marco Teórico | `secciones/marco_teorico.tex` | Conceptos base y estado del arte. |
| Problema | `secciones/problema.tex` | Limitación de ApplicativeDo y formulación del problema. |
| Diseño de Solución | `secciones/diseno_solucion.tex` | Exploración y selección de planes, grafo de precedencia RAW y generación de reordenamientos válidos. |
| Implementación de la Solución | `secciones/implementacion_solucion.tex` | Flujo relevante de GHC, activación, integración en el Renamer, generación de reordenamientos y selección del plan. |
| Validación | `secciones/validacion.tex` | Metodología con métricas integradas, corpus sintéticos, control negativo, alcance y limitaciones. |
| Resultados | `secciones/resultados.tex` | Evidencia agregada, formas del grafo de precedencia RAW, selección por costo, control negativo y discusión. |
| Conclusión | `secciones/conclu.tex` | Resumen final, limitaciones y trabajo futuro. |
| Anexos | `secciones/anexoA.tex` | Reproducibilidad, logs, corpus y detalles técnicos. |

## 1. Introducción

### 1.1 Contexto

Debe introducir programas probabilísticos, Haskell, mónadas y `do-notation` sin entrar todavía en detalles internos de GHC. Conviene usar texto narrativo y referencias a programación probabilística con mónadas.

### 1.2 Problema y Enfoque de Solución

Debe presentar el ejemplo académico probabilístico, sus probabilidades condicionales, dependencias y planes de costo `4 -> 3 -> 2`. Aquí se muestra de forma concisa por qué `ApplicativeDo` mejora el plan sin alcanzar el mínimo y cómo el reordenamiento conmutativo amplía su espacio de búsqueda. El detalle formal queda para Problema y Solución.

### 1.3 Objetivos

Debe presentar objetivo general y objetivos específicos. Los objetivos deben cubrir la comprensión de ApplicativeDo, el diseño del modelo de dependencias, la implementación de la extensión en GHC y su evaluación mediante los dos corpus sintéticos y el control negativo con `IO`.

### 1.4 Contribuciones

Debe enumerar los aportes: extensión en el Renamer, opt-in con `QualifiedDo`, grafo de precedencia RAW, permutaciones topológicas, selección por costo, flag de candidatos, dos corpus sintéticos y control negativo con `IO`.

## 2. Marco Teórico

### 2.1 Fundamentos de Haskell

Debe presentar únicamente las características del lenguaje necesarias para interpretar el resto del informe: pureza, tipado estático, funciones de primera clase, currificación, aplicación parcial, tipos parametrizados, constructores de tipos, clases de tipos e instancias. `Maybe` se introduce aquí como ejemplo común.

### 2.2 Abstracciones funcionales

Debe presentar `Functor`, `Applicative` y `Monad` como una jerarquía de clases de tipos, usando `Maybe` para mostrar las diferencias entre transformación, combinación y dependencia de cómputos.

### 2.3 Do-notation

Debe explicar la relación entre `do` y `>>=`, destacando que el orden monádico introduce alcance y dependencias.

### 2.4 Mónadas conmutativas

Debe explicar la hipótesis semántica que permite reordenar efectos independientes. Es importante aclarar que GHC no prueba conmutatividad.

### 2.5 Mónadas de probabilidad

Debe presentar las mónadas de probabilidad como caso concreto y canónico de mónada conmutativa para el dominio de la memoria. Debe conectar `Dist.T Rational` y la normalización exacta con el ejemplo guía y con el corpus probabilístico.

### 2.6 ApplicativeDo

Debe presentar el trabajo de Marlow et al. y usar las imágenes `imagenes/rearrangement.png` y `imagenes/desugar.png`.

## 3. Problema

### 3.1 Limitación del orden sintáctico de ApplicativeDo

Debe explicar por qué preservar el orden es correcto para mónadas arbitrarias, pero conservador para mónadas conmutativas.

### 3.2 Evidencia del problema y oportunidad

Debe retomar el ejemplo académico presentado en la Introducción y la aplicación de `ApplicativeDo` desarrollada en el Marco Teórico. A partir del orden alternativo `[1,3,2,4]`, debe derivar el plan `(s1 | s3) ; (s2 | s4)` mediante `rearrange` y `split`, mostrar su costo 2 y desarrollar su desazucarado primero con `expr1`--`expr4` y luego con las expresiones probabilísticas reales.

La comparación con el desazucarado del orden original debe evidenciar el mayor uso de operadores aplicativos y establecer la oportunidad de mejora que surge bajo la hipótesis de conmutatividad.

### 3.3 Formulación

Debe formular la brecha entre la corrección de `ApplicativeDo` para mónadas arbitrarias y la libertad adicional de las mónadas conmutativas. La implementación actual de GHC no estudia órdenes alternativos antes de construir el plan, aunque estos puedan exponer un menor costo. La formalización del mecanismo de solución queda para el capítulo siguiente.

## 4. Diseño de Solución

### 4.1 Exploración de reordenamientos y selección de planes

Debe conectar el grafo de precedencia RAW con la generación de reordenamientos válidos, la evaluación de cada secuencia mediante `ApplicativeDo`, la comparación de los árboles producidos y la selección del primer candidato de costo mínimo. Incluye el proceso general de la extensión, destaca la generación de reordenamientos como núcleo del diseño y delimita las responsabilidades del programador y del compilador.

### 4.2 Grafo de precedencia RAW

Debe presentar la primera fase a partir del grafo del ejemplo probabilístico y explicar que sus vértices representan statements y sus aristas las precedencias que deben preservarse.

#### 4.2.1 Modelo de dependencias

Debe desarrollar el modelo general RAW/WAR/WAW y justificar su especialización a RAW después del renombrado de Haskell. Formaliza `WRITE`, `ALL_WRITES` y `READ_local`, distingue binders locales de nombres globales y define la relación de precedencia que debe conservar todo reordenamiento válido.

### 4.3 Generación de reordenamientos válidos

Debe caracterizar los reordenamientos válidos como los ordenamientos topológicos del grafo de precedencia RAW, explicar conceptualmente su enumeración exhaustiva y aplicar la definición al ejemplo probabilístico mediante una tabla con sus cinco ordenamientos. El pseudocódigo y los detalles internos de GHC se reservan para el capítulo de Implementación de la Solución.

## 5. Implementación de la Solución

### 5.1 Flujo de compilación de GHC

Debe presentar la configuración de extensiones, introducir el concepto de AST y explicar la representación parametrizada `HsExpr GhcPs`--`HsExpr GhcRn`--`HsExpr GhcTc`. Conserva la expresión que resume el pipeline Parser--Renamer--Typechecker--Desugarer y termina identificando la infraestructura de opciones dinámicas, el Renamer y los módulos agregados como puntos de intervención.

### 5.2 Activación mediante CommutativeDo

Debe explicar los módulos público e interno `CommutativeDo`, la clase marcador `CommutativeMonad`, el propósito de `QualifiedDo`, el uso de `CD.do` y `CD.return`, y la detección del marcador exportado por el módulo calificador. Incluye un listado breve que adapta la suma monádica presentada en Marco Teórico y muestra los pragmas, la importación calificada, la instancia para `Maybe` y la declaración del bloque experimental.

### 5.3 Integración en el Renamer

Debe explicar el recorrido `HsDo`--`rnStmtsWithFreeVars`--`postProcessStmtsForApplicativeDo`--`rearrangeForApplicativeDo` y justificar la elección del Renamer sin reproducir el código de `rnExpr`. Incluye un diagrama que bifurca primero según `ApplicativeDo` y luego según la resolución del marcador, y que reúne las rutas estándar y conmutativa antes de continuar hacia la etapa siguiente.

### 5.4 Construcción del grafo de precedencia RAW

Debe describir el uso de binders, variables libres, `StmtDepInfo` y `GHC.Data.Graph.Directed`. Conserva el pseudocódigo de construcción y el análisis cuadrático, pero reemplaza los listados de funciones auxiliares de GHC por prosa.

### 5.5 Generación de reordenamientos válidos

Debe explicar la variante ramificada de Kahn representada por `generateAllSemanticTopSorts`, conservar el pseudocódigo recursivo y el árbol de llamadas, referenciar la tabla de ordenamientos presentada en Diseño de Solución y señalar el peor caso factorial.

### 5.6 Generación y selección de planes

Debe explicar cómo cada reordenamiento ingresa en la lógica existente de `ApplicativeDo`, mostrar únicamente las definiciones breves de `StmtTree` y `stmtTreeCost`, describir la selección automática del primer mínimo y cerrar con la continuación por el Typechecker y el Desugarer normales.

## 6. Validación

### 6.1 Metodología

Debe formular las preguntas sobre preservación observable, selección del costo mínimo y activación explícita de la ruta conmutativa. Para PV1 y PV2 explica en una exposición continua cómo se compilan y comparan el programa original, `ApplicativeDo` sobre el orden fuente, el reordenamiento seleccionado automáticamente y cada reordenamiento individual. La opción `-fado-reorder-candidate-n` se presenta aquí exclusivamente como instrumentación de validación y no como parte de la solución. Incluye un diagrama del flujo exhaustivo. Para PV3 describe por separado el flujo reducido de los seis controles de activación.

Las métricas no forman una sección independiente. La metodología debe integrar la instrumentación del Renamer mediante `-ddump-rn-trace` y definir `minimum-cost-perm-index`, `original-cost`, `applicative-do-cost`, `reorder-and-ado-minimum-cost`, `generated-permutations` y `minimum-cost-permutations`. Los artefactos operativos y las trazas completas se reservan para los anexos.

### 6.2 Corpus

Debe describir la jerarquía `<corpus>/cases/<familia>/<caso>/<variante>/` y distinguir 42 variantes compartidas por ambos corpus, cinco específicas de `Maybe` y diez específicas de probabilidades. Las familias compartidas son `dependency-shapes`, `binders`, `let-statements`, `body-stmts`, `shadowing`, `cost-selection` y `controls`; las específicas son `maybe-failure`, `probability-distributions` y `probability-conditioning`.

El capítulo debe registrar 47 programas de `Maybe` y 52 de `Dist.T Rational`, además de mantener el control negativo con `IO` y el ejemplo académico separados conceptualmente de los dos corpus.

### 6.3 Alcance y limitaciones de la validación

Debe delimitar prospectivamente el alcance sintético de los corpus, la naturaleza observacional de la comparación, la dependencia respecto de la instrumentación, la normalización probabilística, la explosión combinatoria, la conmutatividad declarada y el costo estructural uniforme.

## 7. Resultados

### 7.1 Resultados generales

Debe presentar en prosa las 93 comparaciones exhaustivas y los seis controles de activación de los corpus de `Maybe` y `Dist.T Rational`. La preservación observable responde PV1, la coincidencia con el primer mínimo responde PV2 y las trazas `commutative-do` responden PV3. La cantidad de mejoras estrictas no se presenta como una medida agregada de efectividad, porque el corpus prioriza la cobertura semántica y estructural y los casos mejorables fueron construidos deliberadamente con órdenes desfavorables.

### 7.2 Casos destacables

Debe desarrollar casos representativos de `Dist.T Rational`, mostrando para cada uno el bloque `CD.do`, su grafo de precedencia RAW y la interpretación de sus métricas. Incluye `chain-no-reorder/04-minimum`, `diamond/06-minimum`, `no-deps/04`, `two-chains/08-reorder-improves-ado`, `bind-depends-on-let/03`, `tuple-pattern/03-binary`, `choose-dependent/03`, `filter-bind/03` y `read-after-rebind/03`. En todos los grafos, los nodos se ubican sobre una misma línea horizontal y se ordenan de izquierda a derecha según el orden fuente; las aristas no adyacentes se curvan por encima o por debajo para evitar atravesar otros nodos. Fan-in y fan-out permanecen documentados en Corpus, pero no se desarrollan como ejemplos visuales independientes.

### 7.3 Selección por costo

Debe mostrar los cuatro bloques probabilísticos de `all-same-cost`, `original-not-minimal`, `unique-minimum` y `many-minimums`, cada uno acompañado por su grafo RAW. La tabla separa `Sec`, `ADo`, `Extensión`, `Reordenamientos totales` y `Reordenamientos costo mínimo`. Cada caso se introduce con su nombre y caracterización, referencia su código y figura, utiliza captions normalizados y termina con la interpretación de sus aristas, candidatos y costos. El ejemplo académico principal no se repite en esta sección.

### 7.4 Control negativo con IO

Debe presentar narrativamente el control como contraste con la evidencia positiva, mostrar en el código la instancia deliberadamente incorrecta `CommutativeMonad IO` y acompañarla con el grafo RAW vacío. Después interpreta los dos órdenes y sus costos, contrasta mediante una tabla las salidas `A, B, 3` y `B, A, 3`, y explica por qué `RESULT: FAIL` es el desenlace esperado del candidato forzado invertido. Los captions siguen la convención de las secciones anteriores.

### 7.5 Discusión

Debe responder PV1, PV2 y PV3 dentro del alcance establecido en Validación, relacionar las formas del grafo y las construcciones sintácticas con el espacio de búsqueda, separar costo estructural de rendimiento medido y utilizar `IO` para distinguir validez RAW de equivalencia semántica.

## 8. Conclusión

### 8.1 Resumen

Debe resumir el trabajo realizado.

### 8.2 Objetivos

Debe contrastar objetivos con resultados.

### 8.3 Limitaciones

Debe mencionar conmutatividad no probada, explosión combinatoria, validación por salida y modelo de costo uniforme.

### 8.4 Trabajo futuro

Debe incluir refinamiento del modelo de costos, por ejemplo anotaciones `low`, `medium`, `high` con costos 1, 2 y 3.

### 8.5 Cierre

Debe cerrar con el valor de la memoria como extensión experimental reproducible sobre GHC.

## Anexos

### A. Reproducibilidad

Debe documentar Dev Container, toolchain, Makefile y build de GHC.

### B. Pipeline de validación

Debe documentar comandos `make test-ghc`, `make test-cabal` y estructura de resultados.

### C. Logs y trazas

Debe usar `tests/main-example` como recorrido principal de `summary.log`, `graph.log`, `original_ado.log`, `optimal-reorder.log` y `semantic-validation.log`, complementado con casos de los corpus y el control `IO`.

### D. Corpus

Debe contener tablas completas de los corpus sintéticos de `Maybe` y `Dist.T Rational`, además de documentar por separado el control negativo con `IO`.

### E. Implementación

Debe mover aquí detalles técnicos de GHC que sean demasiado densos para el capítulo Implementación de la Solución.

## Imágenes y figuras

- `imagenes/rearrangement.png`: usar en Marco Teórico al explicar Marlow et al.
- `imagenes/desugar.png`: usar en Marco Teórico al explicar desugaring.
- Grafo de precedencia RAW del ejemplo usado en Diseño e Implementación de la Solución: crear con TikZ, ASCII en `verbatim` o una figura externa.
- Pipeline de solución usado en Diseño de Solución: crear como figura nueva.
- Flujo condicional del Renamer usado en Implementación de la Solución: crear con TikZ y distinguir las rutas estándar y conmutativa.
- Pipeline de validación: crear como figura nueva.

## Bibliografía base

El archivo `reports/informe/bibliografia.bib` debe contener las fuentes ya consideradas en la propuesta. Las claves relevantes son:

- `MarlowPJKM2016`
- `marlow_ado`
- `ghc_commit_8ecf6d8`
- `Wadler1995`
- `Mokhov2019`
- `McBride2008`
- `Yorgey2009`
- `Pombrio2018`
- `DavisKeller1982`
- `ScibiorGG2015`
- `Kock2012`
- `Jacobs2018`
- `GHCApplicativeDo`
- `ErwigKollmansberger2006`
- `MarlowNPJ2011`
- `MarlowBCP2014`
- `HarroldSoffa1994`
- `FuzzRDUCC2025`
- `RomeroApplicativeDoRepo`
- `GHCApplicativeDoTestsuite`

## Organización de archivos LaTeX

La estructura acordada usa wrappers de capítulo y archivos por sección:

```text
reports/informe/secciones/
  intro.tex
  marco_teorico.tex
  problema.tex
  diseno_solucion.tex
  implementacion_solucion.tex
  validacion.tex
  resultados.tex
  conclu.tex
  anexoA.tex

  introduccion/*.tex
  marco_teorico/*.tex
  problema/*.tex
  solucion/flujo_solucion.tex
  solucion/modelo_dependencias.tex
  solucion/generacion_reordenamientos.tex
  solucion/implementacion_flujo_ghc.tex
  solucion/implementacion_activacion.tex
  solucion/implementacion_renamer.tex
  solucion/implementacion_grafo.tex
  solucion/implementacion_reordenamientos.tex
  solucion/implementacion_planes.tex
  validacion/*.tex
  resultados/*.tex
  conclusion/*.tex
  anexos/*.tex
```

Cada wrapper de capítulo contiene el `\chapter{...}` y los `\input{...}` de sus secciones.
