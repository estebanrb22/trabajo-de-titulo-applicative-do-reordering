# Estructura del informe final

Este documento registra la estructura acordada para el informe final de memoria. Su objetivo es mantener una guía macro y micro de escritura antes de desarrollar el contenido definitivo en LaTeX.

## Criterios generales

- Usar capítulos con títulos cortos: Introducción, Marco Teórico, Problema, Solución, Validación y Conclusión.
- No usar un capítulo independiente llamado ApplicativeDo en GHC, porque el detalle interno del compilador puede volver denso el informe. Ese contenido se distribuye entre Marco Teórico, Solución y anexos.
- Usar como ejemplo guía el modelo académico probabilístico de `experiments/main-example/main.hs`, porque presenta dependencias y planes de ejecución mediante una historia concreta del dominio de la memoria.
- Mantener el ejemplo guía como caso transversal del informe y distinguirlo de los corpus sintéticos usados para la evaluación agregada.
- Concentrar la validación en dos corpus sintéticos: uno estructural con `Maybe` y otro probabilístico con `Dist.T Rational`; mantener `IO` como control negativo auxiliar y no como un tercer corpus.
- Mencionar el modelo de costo uniforme como limitación actual y proponer su refinamiento como trabajo futuro.

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

Grafo didáctico:

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
| Solución | `secciones/solucion.tex` | Diseño e implementación de la extensión experimental. |
| Validación | `secciones/validacion.tex` | Metodología, corpus sintéticos, control negativo, resultados y amenazas. |
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

Debe enumerar los aportes: extensión en el Renamer, opt-in con `QualifiedDo`, grafo RAW, permutaciones topológicas, selección por costo, flag de candidatos, dos corpus sintéticos y control negativo con `IO`.

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

## 4. Solución

### 4.1 Enfoque propuesto

Debe presentar conceptualmente el opt-in por bloque, la preservación del comportamiento estándar, la generación de órdenes admisibles, su evaluación mediante `ApplicativeDo` y la selección por costo mínimo. Incluye el pipeline conceptual de la extensión.

### 4.2 Diseño algorítmico

Debe desarrollar el modelo general RAW/WAR/WAW y justificar su especialización a RAW después del renombrado de Haskell. Formaliza `WRITE`, `READ_local` y el grafo de precedencia, presenta pseudocódigo para construirlo y enumerar sus ordenamientos topológicos, discute sus costos y aplica el diseño al ejemplo guía.

### 4.3 Implementación en GHC

Debe ubicar la extensión en el pipeline Parser--Renamer--Typechecker--Desugarer, explicar el flujo de `HsDo`, el opt-in con `QualifiedDo`, los módulos conmutativos, `StmtDepInfo`, `GHC.Data.Graph.Directed`, `enumerateSemanticTopSortsBounded`, `StmtTree`, `stmtTreeCost`, la selección automática y `-fado-reorder-candidate-n` como herramienta de validación.

## 5. Validación

### 5.1 Metodología

Debe explicar cómo se compilan y comparan original, ApplicativeDo normal, reordenamiento óptimo y candidatos forzados.

### 5.2 Artefactos de validación

Debe describir `summary.log`, `semantic-validation.log`, `raw.log`, `graph.log`, `optimal-reorder.log`, `original_ado.log` y `permutation_i.log`.

### 5.3 Métricas

Debe definir `original-cost`, `applicative-do-cost`, `reorder-and-ado-minimum-cost`, `generated-permutations` y `minimum-cost-permutations`.

### 5.4 Corpus

Debe describir, como subsecciones, el corpus sintético estructural de `Maybe`, el corpus sintético probabilístico de `Dist.T Rational` y el control negativo con `IO`. Este último debe mantenerse separado conceptualmente de los dos corpus.

### 5.5 Resultados

Debe contener tablas para ambos corpus sintéticos y reportar por separado el resultado esperado del control negativo con `IO`.

El ejemplo guía debe aparecer como resultado representativo independiente, respaldado por `tests/main-example`, sin contabilizarse como un tercer corpus.

### 5.6 Amenazas

Debe discutir el alcance exclusivamente sintético de los corpus, comparación por salida, normalización probabilística, explosión combinatoria, conmutatividad declarada y costo uniforme.

## 6. Conclusión

### 6.1 Resumen

Debe resumir el trabajo realizado.

### 6.2 Objetivos

Debe contrastar objetivos con resultados.

### 6.3 Limitaciones

Debe mencionar conmutatividad no probada, explosión combinatoria, validación por salida y modelo de costo uniforme.

### 6.4 Trabajo futuro

Debe incluir refinamiento del modelo de costos, por ejemplo anotaciones `low`, `medium`, `high` con costos 1, 2 y 3.

### 6.5 Cierre

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

Debe mover aquí detalles técnicos de GHC que sean demasiado densos para Solución.

## Imágenes y figuras

- `imagenes/rearrangement.png`: usar en Marco Teórico al explicar Marlow et al.
- `imagenes/desugar.png`: usar en Marco Teórico al explicar desugaring.
- Grafo RAW del ejemplo usado en Solución: crear con TikZ, ASCII en `verbatim` o una figura externa.
- Pipeline de solución: crear como figura nueva.
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

La estructura acordada usa wrappers de capítulo y archivos por subsección:

```text
reports/informe/secciones/
  intro.tex
  marco_teorico.tex
  problema.tex
  solucion.tex
  validacion.tex
  conclu.tex
  anexoA.tex

  introduccion/*.tex
  marco_teorico/*.tex
  problema/*.tex
  solucion/enfoque_propuesto.tex
  solucion/diseno_algoritmico.tex
  solucion/implementacion_ghc.tex
  validacion/*.tex
  conclusion/*.tex
  anexos/*.tex
```

Cada wrapper de capítulo contiene el `\chapter{...}` y los `\input{...}` de sus subsecciones.
