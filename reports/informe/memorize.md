## 2026-06-25

- Se creo el directorio `secciones/` para organizar los capitulos y anexos del informe.
- Se movieron `intro.tex`, `cap2.tex`, `cap3.tex`, `conclu.tex` y `anexoA.tex` a `secciones/`.
- Se agrego `% !TEX root = ../main.tex` al inicio de cada seccion movida para que VS Code/LaTeX Workshop compile `main.tex` al editar secciones.
- Se actualizaron los `\input` de `main.tex` para apuntar a `secciones/...`.
- Se eliminaron auxiliares LaTeX sueltos en `reports/informe/` y archivos de plantilla no necesarios para escritura (`LICENSE`, `.gitignore`).
- Se recompilo el informe usando `latexmk` con `-auxdir=build` y `-out2dir=.` para dejar auxiliares en `build/` y el PDF final en la raiz del informe.
- Se ajusto la configuracion de VS Code/LaTeX Workshop para usar `-synctex=0`, evitando que `main.synctex.gz` quede junto al PDF final.
- Se creo `secciones/portada.tex` para separar los metadatos de portada (`\depto`, `\author`, `\title`, `\memoria`, `\tesis`, `\guia`, `\comision`, etc.) desde `main.tex`.
- `main.tex` ahora incluye `\input{secciones/portada.tex}` en el preambulo, antes de `\begin{document}`.

## 2026-07-02

- Observacion para escritura futura del informe: presentar RAW/WAR/WAW solo como antecedente general de permutaciones de asignaciones imperativas, no como restricciones internas completas de GHC.
- En el desarrollo teorico, conviene ubicar el modelo general de dependencias en `secciones/cap2.tex` si se requiere introducir el antecedente de prototipado.
- En la implementacion concreta, `secciones/cap3.tex` debe explicar que el Renamer de GHC se especializa a dependencias RAW entre statements, porque los binders renombrados son `Name`s unicos y no existe sobrescritura interna del mismo nombre.
- Mencionar explicitamente que GHC no contempla WAR/WAW como dependencias internas reales en este punto del compilador; esas reglas quedan restringidas al antecedente teorico/prototipo general.
- No se modificaron archivos `.tex` de `reports/informe` en esta actualizacion; estas notas quedan solo como guia para la escritura posterior.

## 2026-07-15

- Se creó `structure.md` en `reports/informe/` para documentar la estructura macro y micro acordada para el informe final.
- Se definió una organización de capítulos con títulos cortos: Introducción, Marco Teórico, Problema, Solución, Validación y Conclusión.
- Se decidió no usar un capítulo independiente `ApplicativeDo en GHC`; ese contenido queda comprimido entre Marco Teórico, Solución y anexos técnicos.
- Se fijó como ejemplo guía el caso `Maybe` de `experiments/maybe-monad/cases/cost-selection/original-not-minimal/04/main.hs`, con costos `4 -> 3 -> 2` para secuencial, `ApplicativeDo` y reordenamiento.
- Se actualizaron los wrappers de capítulo en `secciones/intro.tex`, `secciones/marco_teorico.tex`, `secciones/problema.tex`, `secciones/solucion.tex`, `secciones/validacion.tex`, `secciones/conclu.tex` y `secciones/anexoA.tex`.
- Se eliminaron los placeholders `secciones/cap2.tex` y `secciones/cap3.tex`.
- Se crearon subdirectorios por capítulo bajo `secciones/` y archivos `.tex` por subsección con una primera guía de escritura: propósito, artefactos esperados y posibles contenidos para completar.
- Se actualizó `main.tex` para incluir los nuevos wrappers de Marco Teórico, Problema, Solución y Validación.
- Se reemplazó `bibliografia.bib` del informe por la bibliografía usada en la propuesta de memoria, desde `reports/propuesta/bibliografia.bib`.
- Se corrigieron operadores Haskell dentro de texto LaTeX para evitar problemas con `babel` en español, usando `\verb` en operadores como `(>>=)`, `(<*>)` y flechas `->`.
- Se recompiló `reports/informe/main.tex` con `latexmk`; la compilación finalizó correctamente y actualizó `main.pdf`.
- Se corrigieron tildes y redacción en `structure.md` para mantener documentación consistente en español.
- Se reemplazó la guía de escritura de las cinco subsecciones de Introducción por texto inicial definitivo: contexto, motivación, objetivos, contribuciones y organización.
- Se reemplazó la guía del capítulo Problema por una primera redacción completa del ejemplo `Maybe`, incluyendo limitación del orden sintáctico, grafo RAW, costos `4 -> 3 -> 2` y formulación general.
- Se recompiló nuevamente `main.tex` con `latexmk`; la compilación finalizó correctamente y actualizó `main.pdf`. Quedan solo advertencias de overfull boxes en secciones todavía en estado guía.
- Se reemplazó la guía del capítulo Marco Teórico por una primera redacción base sobre `Functor`, `Applicative`, `Monad`, `do-notation`, mónadas de probabilidad, mónadas conmutativas, `ApplicativeDo` y dependencias RAW.
- Se mantuvieron las figuras de Marlow et al. en la sección `ApplicativeDo` y se conectó el capítulo con la brecha que desarrolla el capítulo Problema.
- Se recompiló `main.tex` con `latexmk`; la compilación finalizó correctamente y actualizó `main.pdf` a 38 páginas.
- Se reemplazó la guía del capítulo Solución por una primera redacción técnica completa: pipeline, `QualifiedDo`, información del Renamer, grafo RAW, permutaciones, evaluación, selección, integración en GHC, selección forzada y artefactos.
- Se incluyó la tabla de candidatos del ejemplo guía con costos, destacando que el candidato original tiene costo 3 y los reordenamientos válidos mínimos tienen costo 2.
- Se ajustó la lista de integración en GHC para usar nombres de módulos en vez de rutas largas, evitando overfull boxes por nombres de archivo extensos.
- Se recompiló `main.tex` con `latexmk`; la compilación finalizó correctamente y actualizó `main.pdf` a 41 páginas.
- Se reemplazó la guía del capítulo Validación por una primera redacción base: metodología, métricas, corpus `Maybe`, corpus probabilístico, corpus real planificado, control `IO`, resultados representativos, amenazas y síntesis.
- Se incorporaron datos concretos del caso guía `Maybe` desde `summary.log`: costos `4`, `3`, `2`, cinco permutaciones generadas y cuatro de costo mínimo.
- Se incorporó el control negativo `IO`, mostrando que una permutación cambia el orden observable de salida y termina en `RESULT: FAIL`.
- Se recompiló `main.tex` con `latexmk`; la compilación finalizó correctamente y actualizó `main.pdf` a 44 páginas.
- Se reemplazó la guía del capítulo Conclusión por una primera redacción base: resumen del trabajo, cumplimiento de objetivos, limitaciones, trabajo futuro y cierre.
- Se agregó una tabla de cumplimiento de objetivos y se dejó el corpus real como parte de Validación, no como trabajo futuro.
- Se incluyó como trabajo futuro el refinamiento del modelo de costos mediante anotaciones o inferencias tipo `low`, `medium` y `high`.
- Se recompiló `main.tex` con `latexmk`; la compilación finalizó correctamente y actualizó `main.pdf` a 46 páginas.
- Se aplicó la reestructuración acordada del informe: Introducción queda sin `Organización`; Marco Teórico queda sin `Síntesis` ni `Dependencias Def-Use y RAW`; Validación queda sin `Síntesis`.
- Se reordenó Marco Teórico para presentar `Mónadas Conmutativas` antes de `Mónadas de Probabilidad`.
- Se eliminó la subsección `Ejemplo Guía` de Problema y se movió el ejemplo `Maybe` al texto introductorio del capítulo.
- Se eliminó `Grafo de Precedencia` de Problema y se movió la explicación formal de dependencias def-use/grafo RAW a Solución.
- Se movió `Artefactos` desde Solución a Validación como `Artefactos de Validación`.
- Se actualizaron los wrappers de capítulos y `structure.md` para reflejar la nueva organización.
- Se recompiló `main.tex` con `latexmk`; la compilación finalizó correctamente y actualizó `main.pdf` a 43 páginas.

## 2026-07-20

- Se reescribió `secciones/introduccion/motivacion.tex` para centrar la motivación en el costo de inferencia probabilística, la independencia oculta por el orden sintáctico, la inconveniencia de reescrituras manuales y la oportunidad de especializar `ApplicativeDo` bajo conmutatividad explícita.

## 2026-07-22

- Se revisó completamente `secciones/marco_teorico/functor_applicative_monad.tex`: se corrigieron firmas de tipos, variables genéricas, aplicación parcial, definiciones e instancias simplificadas de `Maybe`.
- Se reemplazaron las metáforas generales de desempaquetado por explicaciones en términos de transformación y composición contextual.
- Se incorporaron las leyes de `Functor`, `Applicative` y `Monad`, junto con precisiones sobre dependencia de datos, orden de efectos y paralelismo potencial.
- El contenido explicativo nuevo se marcó temporalmente con el color `revisionblue` para facilitar su revisión.
- Se movió la introducción general del Marco Teórico desde el archivo de abstracciones al wrapper `secciones/marco_teorico.tex`.
- Se agregaron las referencias `Haskell2010` y `GHCPrelude` a `bibliografia.bib` para respaldar sintaxis, definiciones, leyes e instancias vigentes.
- Se compiló `main.tex` con `latexmk`; las nuevas referencias se resolvieron y el informe se generó correctamente en `main.pdf`.

- Se revirtió íntegramente la revisión anterior de `secciones/marco_teorico/functor_applicative_monad.tex` por solicitud del autor, restaurando el contenido previo sin pérdidas.
- También se retiraron los cambios auxiliares asociados exclusivamente a esa revisión: el marcado `revisionblue`, las referencias `Haskell2010` y `GHCPrelude`, y el traslado de la introducción general al wrapper del capítulo.
- Se recompiló `main.tex` después de la restauración; el informe se generó correctamente y no quedaron referencias residuales de la revisión revertida.
