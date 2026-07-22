# Estructura del informe final

Este documento registra la estructura acordada para el informe final de memoria. Su objetivo es mantener una guía macro y micro de escritura antes de desarrollar el contenido definitivo en LaTeX.

## Criterios generales

- Usar capítulos con títulos cortos: Introducción, Marco Teórico, Problema, Solución, Validación y Conclusión.
- No usar un capítulo independiente llamado ApplicativeDo en GHC, porque el detalle interno del compilador puede volver denso el informe. Ese contenido se distribuye entre Marco Teórico, Solución y anexos.
- Usar un ejemplo guía con la mónada `Maybe`, porque permite explicar dependencias y planes de ejecución sin introducir el ruido de distribuciones, normalización o soporte probabilístico.
- Reservar los ejemplos con `Dist.T Rational` para Validación, donde corresponde demostrar el dominio probabilístico de la memoria.
- Incluir una sección de corpus real en Validación, aunque sus resultados estén pendientes. No tratar el corpus real como trabajo futuro.
- Mencionar el modelo de costo uniforme como limitación actual y proponer su refinamiento como trabajo futuro.

## Ejemplo guía

El ejemplo guía recomendado corresponde al caso:

```text
experiments/maybe-monad/cases/cost-selection/original-not-minimal/04/main.hs
```

Forma simplificada:

```haskell
mainExample :: Maybe (Int, Int, Int, Int)
mainExample = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 10)
  x3 <- Just 100
  x4 <- Just (x1 + x3)
  CD.return (x1, x2, x3, x4)
```

Statements:

```text
s1 = x1 <- Just 1
s2 = x2 <- Just (x1 + 10)
s3 = x3 <- Just 100
s4 = x4 <- Just (x1 + x3)
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

Este ejemplo permite explicar la mejora incremental: primero se pasa de ejecución secuencial a ApplicativeDo, y luego el reordenamiento conmutativo permite exponer un plan más preciso.

## Capítulos

| Capítulo | Archivo wrapper | Rol |
|---|---|---|
| Introducción | `secciones/intro.tex` | Contexto, motivación, objetivos y contribuciones. |
| Marco Teórico | `secciones/marco_teorico.tex` | Conceptos base y estado del arte. |
| Problema | `secciones/problema.tex` | Limitación de ApplicativeDo y formulación del problema. |
| Solución | `secciones/solucion.tex` | Diseño e implementación de la extensión experimental. |
| Validación | `secciones/validacion.tex` | Corpus sintético, corpus real, resultados y amenazas. |
| Conclusión | `secciones/conclu.tex` | Resumen final, limitaciones y trabajo futuro. |
| Anexos | `secciones/anexoA.tex` | Reproducibilidad, logs, corpus y detalles técnicos. |

## 1. Introducción

### 1.1 Contexto

Debe introducir programas probabilísticos, Haskell, mónadas y `do-notation` sin entrar todavía en detalles internos de GHC. Conviene usar texto narrativo y referencias a programación probabilística con mónadas.

### 1.2 Motivación

Debe explicar por qué el orden escrito de un bloque `do` puede ocultar independencia. Aquí se introduce la intuición de que `ApplicativeDo` ya mejora planes, pero no reordena statements.

### 1.3 Objetivos

Debe presentar objetivo general y objetivos específicos. Los objetivos deben cubrir caracterización de ApplicativeDo, diseño del reordenamiento, integración en GHC, validación sintética y validación con corpus real.

### 1.4 Contribuciones

Debe enumerar los aportes: extensión en el Renamer, opt-in con `QualifiedDo`, grafo RAW, permutaciones topológicas, selección por costo, flag de candidatos y corpus de validación.

## 2. Marco Teórico

### 2.1 Functores, aplicativos y mónadas

Debe presentar las abstracciones funcionales necesarias para entender `ApplicativeDo`.

### 2.2 Do-notation

Debe explicar la relación entre `do` y `>>=`, destacando que el orden monádico introduce alcance y dependencias.

### 2.3 Mónadas conmutativas

Debe explicar la hipótesis semántica que permite reordenar efectos independientes. Es importante aclarar que GHC no prueba conmutatividad.

### 2.4 Mónadas de probabilidad

Debe presentar las mónadas de probabilidad como caso concreto y canónico de mónada conmutativa para el dominio de la memoria. Puede introducir distribuciones discretas y mencionar `Dist.T Rational` como mónada usada en validación.

### 2.5 ApplicativeDo

Debe presentar el trabajo de Marlow et al. y usar las imágenes `imagenes/rearrangement.png` y `imagenes/desugar.png`.

## 3. Problema

### 3.1 Limitación del orden sintáctico

Debe explicar por qué preservar el orden es correcto para mónadas arbitrarias, pero conservador para mónadas conmutativas.

El capítulo introduce el ejemplo `Maybe` como texto inicial, sin subsección propia, y lo usa en las subsecciones siguientes.

### 3.2 Ejecución secuencial

Debe presentar el baseline sin ApplicativeDo, con costo 4.

### 3.3 ApplicativeDo actual

Debe mostrar el plan `s1 ; (s2 | (s3 ; s4))`, con costo 3.

### 3.4 Plan con reordenamiento

Debe mostrar la permutación `[1,3,2,4]` y el plan `(s1 | s3) ; (s2 | s4)`, con costo 2.

### 3.5 Formulación

Debe formular el problema general de forma superficial: ampliar el espacio de órdenes evaluados por ApplicativeDo bajo hipótesis de conmutatividad. La formalización del grafo queda para Solución.

## 4. Solución

### 4.1 Visión general

Debe presentar el pipeline de la extensión desde `CD.do` hasta `ApplicativeStmt` final.

### 4.2 QualifiedDo

Debe explicar `CD.do`, `Control.Monad.CommutativeDo`, `__commutative_do__` y `CommutativeMonad`.

### 4.3 Información del Renamer

Debe explicar que el Renamer entrega statements renombrados y variables libres, suficientes para construir dependencias locales.

### 4.4 Dependencias def-use y grafo RAW

Debe formalizar `WRITE`, `READ_local` y `RAW`, y presentar el grafo como estructura de datos usada para restringir permutaciones.

### 4.5 Permutaciones

Debe explicar ordenamientos topológicos y listar las permutaciones válidas del ejemplo guía.

### 4.6 Evaluación de candidatos

Debe explicar que cada permutación se entrega al algoritmo existente de ApplicativeDo.

### 4.7 Selección

Debe explicar selección por costo mínimo y desempate por primer mínimo.

### 4.8 Integración en GHC

Debe resumir los archivos y módulos relevantes sin detallar internals profundos del compilador.

### 4.9 Selección forzada

Debe explicar `-fado-reorder-candidate-n` como herramienta de validación.

## 5. Validación

### 5.1 Metodología

Debe explicar cómo se compilan y comparan original, ApplicativeDo normal, reordenamiento óptimo y candidatos forzados.

### 5.2 Artefactos de validación

Debe describir `summary.log`, `semantic-validation.log`, `raw.log`, `graph.log`, `optimal-reorder.log`, `original_ado.log` y `permutation_i.log`.

### 5.3 Métricas

Debe definir `original-cost`, `applicative-do-cost`, `reorder-and-ado-minimum-cost`, `generated-permutations` y `minimum-cost-permutations`.

### 5.4 Corpus Maybe

Debe describir el corpus sintético de `Maybe`, ya implementado y testeado.

### 5.5 Corpus probabilístico

Debe describir el corpus sintético de `Dist.T Rational`, ya implementado y testeado.

### 5.6 Corpus real

Debe quedar como sección planificada dentro de Validación. No es trabajo futuro. Debe registrar criterios de selección, protocolo de adaptación y métricas esperadas.

### 5.7 Control IO

Debe explicar el caso negativo con `IO`, donde una permutación cambia el orden observable de salida.

### 5.8 Resultados

Debe contener tablas por corpus y casos representativos.

### 5.9 Amenazas

Debe discutir corpus sintético, comparación por salida, normalización probabilística, explosión combinatoria, conmutatividad declarada y costo uniforme.

## 6. Conclusión

### 6.1 Resumen

Debe resumir el trabajo realizado.

### 6.2 Objetivos

Debe contrastar objetivos con resultados.

### 6.3 Limitaciones

Debe mencionar conmutatividad no probada, explosión combinatoria, validación por salida y modelo de costo uniforme.

### 6.4 Trabajo futuro

Debe incluir refinamiento del modelo de costos, por ejemplo anotaciones `low`, `medium`, `high` con costos 1, 2 y 3. No debe listar corpus real como trabajo futuro.

### 6.5 Cierre

Debe cerrar con el valor de la memoria como extensión experimental reproducible sobre GHC.

## Anexos

### A. Reproducibilidad

Debe documentar Dev Container, toolchain, Makefile y build de GHC.

### B. Pipeline de validación

Debe documentar comandos `make test-ghc`, `make test-cabal` y estructura de resultados.

### C. Logs y trazas

Debe incluir ejemplos representativos de logs.

### D. Corpus

Debe contener tablas completas de casos `Maybe`, casos probabilísticos y, cuando esté definido, corpus real.

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
  solucion/*.tex
  validacion/*.tex
  conclusion/*.tex
  anexos/*.tex
```

Cada wrapper de capítulo contiene el `\chapter{...}` y los `\input{...}` de sus subsecciones.
