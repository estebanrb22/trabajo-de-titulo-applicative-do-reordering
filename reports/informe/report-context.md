# Contexto del informe final

## Organización

La escritura del trabajo de título se encuentra en `reports/informe`. El archivo principal es `main.tex`, los capítulos y subsecciones viven bajo `secciones/`, las figuras están en `imagenes/` y los archivos auxiliares de compilación se concentran en `build/`. La estructura macro y el propósito de cada sección se documentan en `structure.md`; los cambios realizados se registran cronológicamente en `memorize.md`.

El informe se organiza en los capítulos Introducción, Marco Teórico, Problema, Solución, Validación y Conclusión. El detalle interno más denso de GHC se reserva para Solución y anexos, evitando un capítulo independiente sobre `ApplicativeDo` en GHC.

## Ejemplo guía

El caso conductor del informe es el modelo académico probabilístico implementado en:

```text
experiments/main-example/main.hs
```

El programa usa `Dist.T Rational` para representar la distribución conjunta de cuatro variables: preparación del estudiante, resultado de un quiz, dificultad del examen final y resultado del examen. Sus dependencias locales son:

```text
s1 preparation -> s2 quiz
s1 preparation -> s4 finalExam
s3 difficulty  -> s4 finalExam
```

Los resultados reproducibles están en `tests/main-example`. Las fuentes canónicas para el informe son:

- `summary.log`: costos `4 -> 3 -> 2`, cinco permutaciones y cuatro mínimos.
- `graph.log`: aristas `1 -> {2,4}` y `3 -> {4}`.
- `logs/original_ado.log`: plan `preparation ; (quiz | (difficulty ; finalExam))`, costo 3.
- `logs/optimal-reorder.log`: candidato 1, orden `[1,3,2,4]`, plan `(preparation | difficulty) ; (quiz | finalExam)`, costo 2.
- `semantic-validation.log`: salidas y códigos de salida idénticos para el original, `ApplicativeDo`, el óptimo y las cinco permutaciones; resultado final `RESULT: OK`.

Este ejemplo debe aparecer de forma concisa en la subsección `Problema y Enfoque de Solución` de la Introducción y desarrollarse en detalle en Problema y Solución. Validación lo presenta como resultado representativo, pero no como un tercer corpus.

## Alcance experimental

La evaluación agregada considera dos corpus sintéticos: uno estructural con `Maybe` y otro probabilístico con `Dist.T Rational`. El caso con `IO` es un control negativo auxiliar que muestra el riesgo de declarar conmutativa una mónada con efectos observables sensibles al orden. El ejemplo guía es transversal y se mantiene separado de esta clasificación.

El símbolo `|` usado en los planes representa agrupación applicative y paralelismo potencial, no una garantía de ejecución multihilo. Los costos son estructurales y uniformes por statement; no corresponden a mediciones de tiempo de pared.

## Referencias

La bibliografía principal está en `bibliografia.bib`. En `literature/` se conservan artículos, propuestas y antecedentes técnicos sobre Haskell, mónadas, probabilidades, `ApplicativeDo` y reordenamiento. Las memorias y tesis relacionadas se encuentran bajo `literature/reports`.
