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
- Se corrigió la atribución de citas en la introducción de `secciones/marco_teorico/functor_applicative_monad.tex`: `ApplicativeDo` quedó respaldado por Marlow et al. y la guía de GHC, la conmutatividad por Kock y Jacobs, y la jerarquía funcional por Wadler, McBride y Yorgey.
- Se respaldó la instancia real `Functor Maybe` mostrada en `secciones/marco_teorico/functor_applicative_monad.tex` con la referencia `GHCInternalBase`, enlazada al commit exacto del submódulo de GHC utilizado por el proyecto; la cita se resolvió correctamente al recompilar el informe.

## 2026-07-26

- Se eliminó el corpus real del alcance del informe y de la validación experimental; la evaluación queda concentrada en los corpus sintéticos de `Maybe` y `Dist.T Rational`.
- Se mantuvo el caso con `IO` como control negativo auxiliar, separado conceptualmente de los dos corpus sintéticos.
- Se consolidaron las descripciones de `Maybe`, `Dist.T Rational` e `IO` en `secciones/validacion/corpus.tex` y se retiraron los archivos de sección individuales, incluido `secciones/validacion/corpus_real.tex`.
- Se actualizaron objetivos, contribuciones, metodología, resultados, amenazas a la validez, cumplimiento de objetivos, trabajo futuro, cierre y anexos para eliminar compromisos o resultados asociados a un corpus real.
- Se actualizó `structure.md` para reflejar la nueva estructura del capítulo Validación: Corpus, Resultados y Amenazas a la Validez.
- Se recompiló `main.tex` con `latexmk`; la compilación finalizó correctamente, generó un PDF de 50 páginas y confirmó la nueva numeración del capítulo Validación.
- Se creó `secciones/marco_teorico/fundamentos_haskell.tex` para presentar pureza, tipado, funciones de primera clase, currificación, aplicación parcial, tipos parametrizados, constructores de tipos, clases de tipos e instancias antes de introducir las abstracciones funcionales.
- Se movió la introducción general del Marco Teórico al wrapper `secciones/marco_teorico.tex` y se agregó la nueva sección antes de `functor_applicative_monad.tex`.
- `secciones/marco_teorico/functor_applicative_monad.tex` quedó dedicado a `Functor`, `Applicative` y `Monad` bajo la sección `Abstracciones Funcionales`.
- Se actualizó `structure.md` para incorporar `Fundamentos de Haskell` como sección 2.1 y desplazar las secciones posteriores del capítulo.
- Se recompiló `main.tex` con `latexmk`; la compilación finalizó correctamente, actualizó `main.pdf` a 51 páginas y confirmó la numeración 2.1--2.6 del Marco Teórico.
- Se reescribió la presentación de `Applicative` en `secciones/marco_teorico/functor_applicative_monad.tex` para definirla en español como clase de tipos, distinguirla de sus instancias y precisar el papel de `pure` y `(<*>)` en el ejemplo con `Maybe`.
- Se recompiló el informe después de la corrección; `latexmk` finalizó correctamente y actualizó `main.pdf` a 50 páginas.
- Se reemplazó la subsección `Motivación` por `Problema y Enfoque de Solución` y se renombró su archivo como `secciones/introduccion/problema_enfoque_solucion.tex`.
- La Introducción ahora presenta el modelo académico probabilístico de `experiments/main-example/main.hs`, incluyendo sus probabilidades condicionales, dependencias, planes de costo `4 -> 3 -> 2` y validación semántica con `RESULT: OK`.
- El ejemplo académico reemplazó al caso `Maybe` como ejemplo guía transversal en Marco Teórico, Problema, Solución, Validación, Conclusión y anexos; `Maybe` se conserva como apoyo pedagógico y corpus estructural.
- Se actualizaron el grafo RAW, las tablas de candidatos y la selección para usar `preparation`, `quiz`, `difficulty` y `finalExam`, respaldados por `tests/main-example`.
- Se corrigieron las rutas de artefactos para ubicar `graph.log`, `summary.log` y `semantic-validation.log` en la raíz de `tests/main-example`, y las trazas por candidato bajo `tests/main-example/logs/`.
- Se actualizó `structure.md` con el nuevo caso guía y se normalizó `reports-context.md` como `report-context.md`, incorporando la estrategia narrativa y las fuentes canónicas del ejemplo.
- Se recompiló `main.tex` con `latexmk`; la compilación finalizó correctamente, actualizó `main.pdf` a 50 páginas y resolvió las nuevas referencias a la sección, el código y las tablas del ejemplo académico.

## 2026-07-27

- Se corrigió y fundamentó `secciones/introduccion/contexto.tex` mediante referencias específicas para la definición y aplicaciones de la programación probabilística, las estrategias de muestreo e inferencia, las mónadas de probabilidad en Haskell, la `do-notation` y `ApplicativeDo`.
- Se reemplazaron afirmaciones imprecisas sobre generación de números aleatorios y ciberseguridad por aplicaciones documentadas, incluyendo protocolos criptográficos, aprendizaje automático e inteligencia artificial.
- En el ejemplo de moneda y dado, se distinguieron resultados de eventos y se precisó que el soporte de la distribución conjunta contiene doce pares equiprobables.
- Se agregó la traducción normativa de statements `do` según la sección 3.14 del Haskell 2010 Language Report y se citó directamente la preservación del orden de `ApplicativeDo` desde Marlow et al., páginas 94--95.
- Se incorporaron las entradas bibliográficas `GordonHNR2014`, `Ghahramani2015` y `Haskell2010` en `bibliografia.bib`.
- Se recompiló `main.tex` con `latexmk`; el PDF se generó correctamente en 50 páginas, las nuevas citas quedaron resueltas y no se introdujeron advertencias tipográficas en la sección Contexto.
- Se agregó en `main.tex` una infraestructura parametrizable para tablas basada en colores semánticos, con `\settabletheme`, parámetros de espaciado, encabezados reutilizables, filas destacadas y columnas extensibles.
- El tema inicial de tablas reutiliza la paleta de los bloques de código: `codebg`, `codeframe`, `codekeyword` y `codestring`; las variantes futuras pueden cambiar los siete parámetros cromáticos sin modificar la estructura de las tablas.
- Se migraron las dos tablas de `secciones/introduccion/problema_enfoque_solucion.tex` a `booktabs`, encabezados coloreados, bandas alternadas y leyendas superiores; la fila de reordenamiento se marcó mediante el color semántico de destacado.
- Se recompiló el informe con `latexmk`; el PDF se generó correctamente en 50 páginas y la sección modificada no introdujo advertencias tipográficas nuevas.
- Se intensificó el tema global de tablas usando mezclas de `codekeyword`, `codebg` y `codeframe`, manteniendo todos los colores centralizados en `\settabletheme`.
- Se agregó el componente reutilizable `\TableFrame`, con un ancho parametrizable de `0.5pt`, para dibujar un perímetro sin introducir reglas internas.
- La Tabla 1.1 de `secciones/introduccion/problema_enfoque_solucion.tex` quedó rodeada por `\TableFrame`; conserva el encabezado y las filas continuas, sin separadores horizontales internos.
- Se recompiló y revisó visualmente `main.pdf`; el informe conserva 50 páginas y la tabla modificada no produce advertencias tipográficas nuevas.
- Se agregó `\TableFontSize` con valor `\small` y se aplicó globalmente al inicio de los entornos `tabular` y `tabularx` mediante `etoolbox`; las leyendas conservan el tamaño definido por la plantilla.
- Se recompiló y revisó visualmente el informe en las tablas 1.1, 1.2 y Cumplimiento de Objetivos; las tablas usan 10.95 pt frente a los 12 pt del cuerpo y permanecen dentro de los márgenes.
- El ajuste de flujo redujo `main.pdf` a 49 páginas. Permanecen dos avisos `underfull` en las columnas justificadas de la tabla de objetivos, sin desbordes ni errores de compilación.
- Se definió `\ElementCaptionGap` con `8pt` y se configuraron las leyendas de tablas, figuras y códigos para aparecer debajo de sus elementos; `lstlisting` usa ahora `captionpos=b` y separación inferior parametrizada.
- Se movieron las leyendas y etiquetas de las tablas 1.1 y 1.2 después de sus respectivos contenidos, manteniendo cada `\label` inmediatamente después de `\caption` para preservar las referencias.
- Se recompiló y revisó visualmente el informe en la Tabla 1.1, el Código 1.1, el grafo de precedencia, la Tabla 1.2 y las figuras de `ApplicativeDo`; las leyendas conservan una separación uniforme y las referencias permanecen resueltas.
- `main.pdf` conserva 49 páginas y no se introdujeron errores ni advertencias tipográficas nuevas por la ubicación de las leyendas.
- Se incorporó TikZ con la librería `positioning` y se creó en `main.tex` una infraestructura parametrizable para grafos de precedencia, siguiendo la separación visual ya usada por códigos y tablas.
- El estilo de grafos centraliza colores semánticos, dimensiones, separaciones, tipografías, grosores y curvatura, además de proporcionar el entorno `PrecedenceGraph` y los comandos `\PrecedenceNode` y `\PrecedenceEdge`.
- Se agregó a `secciones/introduccion/problema_enfoque_solucion.tex` el grafo del ejemplo académico con los nodos `preparation`, `quiz`, `difficulty` y `finalExam`, las etiquetas inferiores $s_1$--$s_4$ y las aristas RAW $s_1 \to s_2$, $s_1 \to s_4$ y $s_3 \to s_4$.
- Se explicó que `s2` y `s3` no tienen un orden relativo impuesto por el grafo, por lo que `[1,2,3,4]` y `[1,3,2,4]` respetan las mismas precedencias y, bajo conmutatividad, conservan la distribución normalizada.
- Se recompiló y revisó visualmente `main.pdf`; la figura se mantuvo dentro de los márgenes en la página 3, el informe conservó 49 páginas y no aparecieron advertencias nuevas en la sección modificada.
- Se cambió el estilo global de los nodos de precedencia desde rectángulos redondeados a círculos uniformes, parametrizados mediante `\GraphNodeMinSize` con un diámetro mínimo de `2.3cm`.
- La fuente del contenido interno de los nodos se redujo a `\scriptsize`, mientras que las etiquetas inferiores $s_1$--$s_4$ conservaron `\small` mediante `\GraphLabelFont`.
- Se recompiló y revisó visualmente `main.pdf`; los cuatro círculos mantienen el mismo tamaño, `preparation` cabe en una línea, las aristas conservan sus anclajes y el informe permanece en 49 páginas.
- Se reemplazaron los nodos circulares por óvalos mediante la forma `ellipse` de la librería TikZ `shapes.geometric`.
- Se agregó `\setgraphnodesize{largo}{alto}{fuente}` para controlar conjuntamente `\GraphNodeWidth`, `\GraphNodeHeight` y `\GraphNodeFontSize`; la configuración inicial usa `2.7cm`, `1.7cm` y `9pt`.
- El espaciado interior se redujo a `1pt` para evitar que los nombres más largos expandan sus nodos, manteniendo cuatro óvalos uniformes y conservando `\GraphLabelFont` para las etiquetas $s_1$--$s_4$.
- Se recompiló y revisó visualmente `main.pdf`; el grafo permanece dentro de los márgenes en la página 3, conserva 49 páginas y no introduce advertencias nuevas.

## 2026-07-28

- Se amplió `secciones/introduccion/problema_enfoque_solucion.tex` para explicar que un orden candidato dispuesto horizontalmente es válido cuando todas las aristas de precedencia avanzan de izquierda a derecha; una arista hacia la izquierda representaría una dependencia invertida.
- Se distinguió la preservación de dependencias, que hace válido el orden `[1,3,2,4]`, de la hipótesis de conmutatividad, que permite afirmar su equivalencia semántica con el orden original.
- Se agregó un segundo grafo con los nodos en el orden `s1`, `s3`, `s2`, `s4` y las mismas dependencias RAW `s1 -> s2`, `s1 -> s4` y `s3 -> s4`; sus curvaturas se ajustaron para evitar cruces entre aristas.
- El análisis de costos quedó separado en los casos secuencial, `ApplicativeDo` y reordenamiento, seguido por la tabla comparativa como síntesis; la tabla alinea la variante a la izquierda y centra el plan y el costo.
- Se compiló el informe con `latexmk` y se revisó visualmente la sección modificada; ambos grafos, la tabla y sus leyendas permanecen dentro de los márgenes, las referencias se resolvieron y el PDF resultante tiene 50 páginas.
- Se reemplazó el análisis individual previo de los tres planes por una presentación común de la notación: `;` representa composición secuencial y `|` agrupación aplicativa con paralelismo potencial.
- Se formalizó el modelo estructural de costos mediante las reglas `C(s_i)=1`, suma para composición secuencial y máximo para agrupaciones aplicativas, precisando que la métrica representa el camino crítico y no tiempo de ejecución.
- La tabla de planes quedó como evidencia central de la comparación `4 -> 3 -> 2`, con la fila de reordenamiento destacada y una leyenda referida explícitamente a costos estructurales.
- Después de la tabla se separaron la formulación de la limitación del orden sintáctico, el enfoque de solución basado en `CD.do` y la evidencia de validación del ejemplo.
- Se compactó la redacción y se usó colocación preferente `[!ht]` para mantener la tabla después de las reglas de costo y antes de su interpretación; la inspección visual confirmó el orden correcto de lectura y la ausencia de advertencias tipográficas nuevas en la subsección.
- Se agregó antes de la notación de planes una definición de `plan de ejecución` como representación abstracta de la composición de los cómputos, distinguiéndola de una planificación concreta de hilos o de tiempos reales.
- La transición posterior ahora conecta explícitamente el orden válido determinado por el grafo con los operadores conceptuales `;` y `|` usados para escribir los planes del ejemplo.
- Se recompiló y revisó visualmente el informe; la definición nueva se integra después del segundo grafo, la tabla conserva su posición narrativa y la subsección no introduce advertencias tipográficas nuevas.
- Se reformularon los dos párrafos finales de `secciones/introduccion/problema_enfoque_solucion.tex` para describir la solución como una ampliación del espacio de búsqueda de `ApplicativeDo`, basada en órdenes alternativos que preservan precedencias bajo una hipótesis explícita de conmutatividad.
- La aplicación al ejemplo distingue ahora cinco órdenes válidos, identifica `[1,3,2,4]` como el primer candidato de costo mínimo y conecta explícitamente ese resultado con el plan de costo 2 de la tabla.
- La validación quedó descrita mediante las variantes efectivamente ejecutadas y como evidencia experimental de preservación semántica para el ejemplo, evitando afirmar una garantía general.
- Se compiló y revisó visualmente el cierre de la subsección; los párrafos permanecen junto a la tabla, las referencias están resueltas y no se introdujeron advertencias tipográficas nuevas.
- Se aplicó una revisión final de consistencia en `secciones/introduccion/problema_enfoque_solucion.tex`: las probabilidades del texto usan notación matemática y el orden reordenado se expresa uniformemente como `[1,3,2,4]`.
- Las leyendas de los grafos distinguen ahora de forma concisa las disposiciones original y reordenada; se conservó sin cambios la explicación del sentido horizontal de las aristas escrita por el autor.
- Se ajustaron el tiempo verbal de la notación de planes, la enumeración de los tres casos comparados en la tabla y la formulación de la limitación bajo conmutatividad.
- La compilación con `latexmk` y la inspección visual confirmaron que figuras, referencias, fórmula de costos y tabla permanecen correctamente dispuestas, sin advertencias nuevas en la subsección.

## 2026-07-29

- Se centralizó en `main.tex` la política de posicionamiento de elementos mediante el paquete `placeins` y barreras automáticas después de los entornos `figure` y `table`.
- Las barreras impiden que los párrafos posteriores adelanten una figura o tabla desplazada a la página siguiente; los entornos `lstlisting` se mantienen explícitamente como elementos no flotantes mediante `float=false`.
- Se recompiló y revisó `main.pdf`; la Figura 2.2 aparece al inicio de la página 18 y el texto posterior queda debajo de ella, conservando el orden narrativo. El informe resultante tiene 51 páginas.
- Se configuró globalmente `caption` con `justification=centering` y `singlelinecheck=false` para centrar las leyendas de figuras, tablas y códigos, incluidas las que ocupan varias líneas.
- Se recompiló y revisó visualmente `main.pdf`; la Tabla 1.1, el Código 1.1 y la leyenda multilínea de la Figura 1.2 aparecen centrados. El documento resultante tiene 50 páginas.
- Se reformuló el objetivo general de `secciones/introduccion/objetivos.tex` para presentar de manera positiva la selección de un plan de menor costo cuando un reordenamiento admisible lo permita.
- Los objetivos específicos ahora distinguen el reconocimiento de una marca explícita de conmutatividad, la preservación de dependencias locales y los dos ejes de validación: resultados observables y costo estructural.
- Se armonizó la tabla de `secciones/conclusion/objetivos.tex` con la nueva formulación de los cuatro objetivos.
- Se forzó la recompilación completa con `latexmk` y se revisaron las páginas de Objetivos y Cumplimiento de Objetivos; ambas permanecen dentro de los márgenes y el PDF conserva 51 páginas.
- Se resumió `secciones/introduccion/contribuciones.tex` de siete aportes específicos a tres contribuciones de alto nivel: el mecanismo de reordenamiento semántico, su integración experimental en GHC y la validación reproducible de resultados y costos.
- Se eliminaron de esta sección introductoria las referencias prematuras a módulos, flags, estructuras internas y archivos del repositorio, manteniendo el alcance experimental de las afirmaciones.
- Se recompiló `main.tex` con `latexmk`; la compilación finalizó correctamente, la sección no introdujo advertencias tipográficas y `main.pdf` quedó en 50 páginas.
- Se agregaron referencias específicas a todos los párrafos conceptuales de `secciones/marco_teorico/fundamentos_haskell.tex`, cubriendo características generales de Haskell, pureza y efectos, currificación, aplicación parcial, tipos parametrizados, `Maybe`, clases de tipos e instancias.
- Las afirmaciones normativas quedaron respaldadas por secciones concretas de `Haskell2010`; la composición de efectos usa además `Wadler1995`, y la jerarquía moderna con las instancias de `Maybe` usa `Yorgey2009` y `GHCInternalBase`.
- Se generalizó la nota de `Haskell2010` en `bibliografia.bib` para describir el informe oficial completo, en vez de limitarla a la sección 3.14 sobre `do`.
- Se recompiló `main.tex` con `latexmk`; BibTeX resolvió todas las citas, `main.pdf` se actualizó correctamente a 50 páginas y la sección modificada no introdujo advertencias tipográficas.
- Se reescribió `secciones/marco_teorico/do_notation.tex` para derivar gradualmente la `do-notation` desde la suma monádica `Just 3 >>= (\x -> Just 5 >>= (\y -> return ((+) x y)))`.
- La subsección presenta primero la expresión compacta, luego su distribución visual en varias líneas y finalmente el bloque `do` equivalente con statements que vinculan `x` e `y`.
- Se explicó que el reformateo no cambia el orden semántico, que la evaluación produce `Just 8` y que `Just 5` no depende localmente de `x`, conectando así orden sintáctico, dependencias de datos, mónadas conmutativas y `ApplicativeDo`.
- Se compiló `main.tex` con `latexmk` y se revisaron visualmente las páginas 13 y 14; los tres bloques de código permanecen dentro de los márgenes, las citas se resolvieron y la subsección no introdujo advertencias tipográficas.
- Se agregó al listado de la firma de `(+)` en `secciones/marco_teorico/fundamentos_haskell.tex` la leyenda `Firma de tipos del operador de suma (+).` y el identificador `lst:sum-type-signature`.
- El párrafo introductorio ahora referencia explícitamente el listado como Código 2.1 mediante `\ref{lst:sum-type-signature}`.
- Se recompiló `main.tex` con `latexmk`; la referencia quedó resuelta, la subsección no introdujo advertencias tipográficas y `main.pdf` quedó en 51 páginas.
- Se agregaron leyendas descriptivas y etiquetas `lst:` a los 11 bloques de código de `secciones/marco_teorico/functor_applicative_monad.tex`, cubriendo las definiciones, instancias y ejemplos de `Functor`, `Applicative` y `Monad`.
- Los párrafos introductorios ahora citan explícitamente cada listado mediante `Código~\ref{...}`, sin modificar el contenido Haskell de los ejemplos.
- Se recompiló e inspeccionó `main.pdf`; las referencias se resolvieron consecutivamente como códigos 2.2--2.12, las leyendas quedaron centradas bajo sus bloques y la sección no introdujo advertencias tipográficas nuevas. El documento conserva 51 páginas.
- Se eliminó de `secciones/marco_teorico/do_notation.tex` la repetición compacta de la suma monádica y se reemplazó por una referencia al Código~`\ref{lst:monad-maybe-sum}` de la subsección anterior.
- Se retiró el párrafo que volvía a explicar la anidación de las funciones anónimas y se concentró la nueva redacción en la diferencia entre la disposición compacta, la forma multilínea y la `do-notation`.
- Los dos códigos propios de la sección recibieron las etiquetas `lst:monad-maybe-sum-multiline` y `lst:do-notation-maybe-sum`, junto con leyendas y referencias explícitas desde el texto.
- El ejemplo se normalizó a `Just 3` y `Just 2`, por lo que ambas representaciones coinciden literalmente con el código anterior y producen `Just 5`.
- El bloque de `do-notation` se mantuvo unido con su leyenda mediante un `minipage` local, evitando que el código se divida entre las páginas 14 y 15.
- Se recompiló e inspeccionó `main.pdf`; las referencias quedaron resueltas como códigos 2.11, 2.13 y 2.14, ambos códigos nuevos permanecen completos y la subsección no introdujo advertencias tipográficas. El informe conserva 51 páginas.
- Se reescribió `secciones/marco_teorico/monadas_conmutativas.tex` como una exposición exclusivamente conceptual, eliminando las referencias previas al grafo de dependencias, `QualifiedDo` y la implementación experimental.
- La definición quedó fundamentada mediante la igualdad de los mapas de Fubini de Kock y la interpretación operacional de Marlow et al.; la conexión probabilística se restringió al resultado de Jacobs para la mónada de distribuciones discretas finitas.
- Se retomó la suma monádica con `Maybe` para comparar los órdenes original y reordenado de `x <- Just 3` e `y <- Just 2`, aclarando que ambos producen `Just 5` por la conmutatividad de la mónada y no por la del operador de suma.
- Se distinguieron independencia estructural y conmutatividad semántica, se caracterizó `Maybe` bajo una semántica total y se conservó `IO` únicamente como contraste conceptual de efectos observables sensibles al orden.
- El nuevo Código 2.15 se mantuvo unido con su leyenda mediante un `minipage`; la compilación con `latexmk` y la revisión visual confirmaron referencias resueltas, ausencia de advertencias nuevas en la subsección y un PDF final de 52 páginas.
- Se reescribió `secciones/marco_teorico/monadas_probabilidad.tex` para presentar las distribuciones discretas finitas mediante la implementación concreta `Dist.T Rational` del paquete externo `probability`.
- Se documentó el módulo público `Numeric.Probability.Distribution` y su representación interna `newtype T prob a = Cons { decons :: [(a, prob)] }`, destacando la presencia de ramas repetidas, la multiplicación de probabilidades durante `>>=` y la exactitud de `Rational`.
- El ejemplo de moneda y dado quedó solo como referencia a la Introducción y se incorporó un modelo de clima y actividades que combina `Dist.fromFreqs`, `Dist.choose` y `Dist.uniform`; el texto deriva exactamente la probabilidad `19/100` para uno de sus resultados.
- Se precisó que `Dist.fromFreqs` convierte frecuencias en probabilidades, mientras que `Dist.norm` agrupa resultados iguales y suma sus pesos sin reescalarlos; la equivalencia conmutativa usada por la memoria se formula sobre distribuciones normalizadas y no sobre el orden literal de `decons`.
- Se agregó la referencia `HackageProbabilityDistribution` a `bibliografia.bib` para respaldar la API y la definición interna del módulo utilizado.
- Se recompiló e inspeccionó visualmente `main.pdf`; los códigos 2.16 y 2.17, la ecuación y las referencias quedaron correctamente dispuestos, la subsección no introdujo desbordes tipográficos y el informe resultante tiene 54 páginas.

## 2026-07-30

- Se reescribió `secciones/marco_teorico/applicative_do.tex` para desarrollar conceptualmente el pipeline de `ApplicativeDo` mediante las etapas `rearrange` y `desugaring`, conservando el primer párrafo de la sección.
- La etapa de `rearrange` ahora explica la notación `do l e`, las funciones `segments` y `split`, la condición de corte basada en variables vinculadas y libres, y la relación `def-use`, sin repetir el modelo de costos ya definido en la Introducción.
- La etapa de `desugaring` desarrolla los cinco casos del algoritmo y la función `desugar_arg`, manteniendo las figuras originales de Marlow et al. con citas específicas a las páginas 95 y 96.
- La aplicación del algoritmo reutiliza el modelo probabilístico del estudiante, deriva el plan `s1 ; (s2 | (s3 ; s4))` y presenta el resultado del desazucarado primero con `expr1`--`expr4` y luego con las expresiones probabilísticas reales.
- Se recompiló e inspeccionó visualmente `main.pdf`; las figuras, la ecuación, los planes y los códigos 2.18--2.21 permanecen dentro de los márgenes, las referencias se resolvieron y el informe resultante tiene 58 páginas.
- Se cargó `thmtools` desde `umemoria.cls` para extender los entornos matemáticos existentes sin reemplazar su numeración compartida.
- Se agregó en `main.tex` un Índice de Definiciones que incluye exclusivamente entornos `defn` con título opcional.
- El modelo estructural de costos de `secciones/introduccion/problema_enfoque_solucion.tex` quedó como la Definición 1.1, titulada `Modelo de costos estructural` y etiquetada como `def:modelo-costos-estructural`.
- Marco Teórico, Problema, Solución y Validación ahora remiten al modelo mediante referencias cruzadas, en lugar de repetir o mencionar informalmente su ubicación.
- Los cálculos concretos de costo de `secciones/problema/ejecucion_secuencial.tex`, `applicative_do_actual.tex` y `plan_con_reordenamiento.tex` quedaron numerados y referenciados como ecuaciones.
- Se documentó el mecanismo de definiciones y ecuaciones en `README.md`, y se corrigieron errores ortográficos en la descripción de los entornos matemáticos.
- Se configuró `theHlstlisting` en `main.tex` con capítulo y contador local para evitar destinos PDF duplicados en la numeración de códigos.
- Se forzó la recompilación completa con `latexmk`; `main.pdf` quedó en 59 páginas, el índice contiene la Definición 1.1, las ecuaciones se resolvieron como 3.1--3.3 y no quedaron referencias ni citas indefinidas. Permanece el aviso previo por el destino duplicado `page.i`.
- Se reformuló el mecanismo anterior para no clasificar el modelo de costos como una definición: se retiraron `thmtools`, el Índice de Definiciones y las referencias agregadas a `def:modelo-costos-estructural`.
- Se incorporó en `main.tex` el entorno no flotante `ReportExpression`, con numeración independiente por capítulo, leyenda inferior y etiquetas `expr:` para fórmulas, firmas y representaciones abstractas; no se genera un índice adicional.
- Se aplicó `ReportExpression` sin alterar su contenido al modelo de costos, al cálculo de la probabilidad de `(Outdoor, 1)`, a la condición de independencia, a la firma de `desugar`, a la entrada y los resultados de `rearrange`, y a los tres cálculos de costo del capítulo Problema.
- Se restauró la estructura expositiva de los costos y se retiraron las referencias inmediatas añadidas a definiciones y ecuaciones; los labels quedan disponibles para futuras referencias mediante `Expresión~\ref{expr:...}`.
- Se actualizó `README.md` con el uso de `ReportExpression` y se conservó la corrección de destinos PDF únicos para los códigos.
- La compilación forzada y la inspección visual confirmaron las expresiones 1.1, 2.1--2.5 y 3.1--3.3 correctamente dispuestas; `main.pdf` quedó en 58 páginas. Permanece el aviso previo por el destino duplicado `page.i` y los desbordes tipográficos ajenos a estos bloques.
- El contador y el `label` de `ReportExpression` se ubicaron junto a la leyenda dentro del bloque para que, cuando una expresión salta de página, la referencia y el hipervínculo apunten a su página visual efectiva.
- Se restauró en `secciones/introduccion/problema_enfoque_solucion.tex` el párrafo introductorio completo del modelo de costos como texto normal y se mantuvo unido a la expresión mediante `samepage`.
- Las tres reglas del modelo de costos quedaron alineadas horizontalmente en una sola fila, conservando la leyenda y el label `expr:modelo-costos-estructural`.
- La compilación e inspección visual confirmaron que el párrafo y la expresión permanecen juntos, la fila cabe dentro de los márgenes y `main.pdf` conserva 58 páginas.
- Se reestructuró el capítulo Problema para conservar únicamente `Limitación del Orden Sintáctico de ApplicativeDo`, `Evidencia del Problema y Oportunidad` y `Formulación`.
- Se eliminaron las subsecciones y archivos `ejecucion_secuencial.tex`, `applicative_do_actual.tex` y `plan_con_reordenamiento.tex`; su función expositiva fue reemplazada por `secciones/problema/evidencia_problema_oportunidad.tex`.
- La nueva evidencia retoma el ejemplo probabilístico y deriva el orden `[1,3,2,4]`: la llamada exterior a `segments` mantiene un único segmento, mientras `split` selecciona `i=2` y obtiene `(s1 | s3) ; (s2 | s4)` con costo 2.
- Se desarrolló el desazucarado del plan primero con `expr1`--`expr4` y luego con las expresiones reales; la forma resultante usa `join` y dos apariciones de `(<*>)`, frente a una en el desazucarado del orden original.
- Se reescribió `Formulación` para centrar la brecha entre la corrección de `ApplicativeDo` sobre mónadas arbitrarias y la oportunidad de estudiar órdenes alternativos para mónadas conmutativas, sin anticipar el mecanismo concreto de la solución.
- Se actualizó `structure.md` y se mantuvo unido el Código 3.3 mediante `minipage` después de revisar visualmente las páginas 27--30 del capítulo.
- La compilación con `latexmk` finalizó correctamente, generó un PDF de 59 páginas y resolvió las nuevas expresiones 3.1--3.2 y los códigos 3.1--3.4 sin referencias ni citas indefinidas. El capítulo Problema no introdujo advertencias tipográficas nuevas; permanecen avisos previos en otras secciones y el destino duplicado `page.i`.
- Se reorganizó por completo el capítulo Solución en tres secciones principales: `Enfoque Propuesto`, `Diseño Algorítmico` e `Implementación en GHC`, precedidas por un párrafo que anticipa el recorrido del capítulo.
- Los nueve archivos fragmentados anteriores se reemplazaron por `secciones/solucion/enfoque_propuesto.tex`, `diseno_algoritmico.tex` e `implementacion_ghc.tex`; `secciones/solucion.tex` ahora funciona como wrapper y presentación del capítulo.
- El enfoque conceptual incorpora un pipeline TikZ desde la declaración conmutativa hasta la selección del candidato de menor costo, delimitando la validez de los órdenes al modelo RAW y a la hipótesis declarada de conmutatividad.
- El diseño algorítmico formaliza RAW, WAR y WAW como antecedente general, justifica la especialización a RAW mediante binders renombrados con identidades únicas, define `WRITE` y `READ_local`, y presenta pseudocódigo para construir el grafo y enumerar sus ordenamientos topológicos.
- La implementación documenta el pipeline `GhcPs`--`GhcRn`--`GhcTc`, el flujo de `HsDo`, el opt-in mediante `QualifiedDo`, los módulos `CommutativeDo`, `StmtDepInfo`, `GHC.Data.Graph.Directed`, `StmtTree`, el cálculo de costos, la selección con `minimumBy` y la flag `-fado-reorder-candidate-n`.
- Se agregó la referencia oficial `GHCQualifiedDo` a `bibliografia.bib` y labels a Fundamentos de Haskell, Do-Notation, Mónadas Conmutativas y Formulación para reutilizar contenido previo mediante referencias cruzadas.
- Se actualizó `structure.md` con la nueva organización y se mantuvieron unidos mediante `minipage` los fragmentos de código que podían dividirse entre páginas.
- La compilación completa con `latexmk` finalizó correctamente y generó un PDF de 65 páginas. La inspección visual de las páginas 31--43 confirmó que la figura, expresiones, tabla y códigos permanecen dentro de los márgenes y que el capítulo no introduce desbordes tipográficos; permanecen únicamente advertencias previas en Validación, bibliografía y anexos, además del destino duplicado `page.i`.
- Se reescribió el tramo inicial de `Modelo de Dependencias` en `secciones/solucion/diseno_algoritmico.tex`, conservando su contenido conceptual y mejorando la transición desde el modelo general RAW/WAR/WAW hacia la especialización aplicada dentro del Renamer.
- La redacción distingue ahora una sobrescritura imperativa del ocultamiento léxico de Haskell y precisa que el Renamer asigna un `Name` único a cada binder; los sufijos visibles se presentan como una representación legible de esas identidades, no como la semántica del renombrado.
- El Código 4.1 se amplió con un binder intermedio `y` que lee la primera identidad de `x` antes de introducir una segunda vinculación textual de `x`. El ejemplo permite demostrar por intersecciones vacías la ausencia de WAW y WAR, además de identificar la dependencia RAW efectiva entre la primera definición y `y`.
- Se incorporaron referencias a `DavisKeller1982` y `HarroldSoffa1994` para respaldar el antecedente general de dependencias y se mantuvo la referencia a `Haskell2010` para pureza y alcance léxico.
- El informe se recompiló con `latexmk` y se inspeccionaron visualmente las páginas 33 y 34. El ejemplo permanece completo, sus columnas son legibles, no se introdujeron desbordes tipográficos en Solución y `main.pdf` quedó en 66 páginas.
- Se finalizó la subsección `Modelo de Dependencias` de `secciones/solucion/diseno_algoritmico.tex` con la distinción entre el conjunto completo de `FreeVars` informado por el Renamer y las lecturas producidas localmente por el bloque.
- La nueva explicación indica que `FreeVars` puede incluir referencias a binders anteriores y nombres globales, como funciones, operadores y constructores, mientras `ALL_WRITES` reúne únicamente los `Name`s introducidos por los statements. La intersección de ambos conjuntos define `READ_local` y descarta referencias externas como `Just` y `(*)`.
- Se desarrollaron individualmente `WRITE`, `ALL_WRITES`, `FV` y `READ_local`, se explicó la condición de la arista RAW mediante un `Name` testigo y se cerró la subsección enlazando estas relaciones con la posterior construcción del grafo de precedencia.
- La compilación con `latexmk` generó correctamente un PDF de 66 páginas, sin referencias o citas indefinidas ni desbordes nuevos en Solución. La inspección visual de las páginas 34 y 35 confirmó que las expresiones 4.2 y 4.3 y la transición hacia `Construcción del Grafo de Precedencia` permanecen legibles y bien distribuidas.
- Se ajustó `Construcción del Grafo de Precedencia` en `secciones/solucion/diseno_algoritmico.tex` para definir explícitamente `n` como la cantidad de statements que participan en el reordenamiento, excluyendo el statement terminal que permanece fijo.
- El pseudocódigo calcula ahora `n := length(statements)` antes de crear los vértices y utiliza notación prefija consistente para `intersection(freeVars(s_i), allWrites)` e `intersection(writesLocal[i], readsLocal[j])`.
- Se conservó el cierre agregado que aplica el algoritmo al Código 1.1 y referencia el grafo de la Figura 1.1. La compilación mantuvo el informe en 66 páginas, sin referencias indefinidas ni advertencias nuevas en Solución; las páginas 35 y 36 fueron inspeccionadas visualmente y el Código 4.2 permanece completo en una sola página.
- Se reestructuró `Enumeración de Reordenamientos Válidos` en `secciones/solucion/diseno_algoritmico.tex` mediante las subsubsecciones `Algoritmo de Kahn` y `Enumeración Exhaustiva`.
- La exposición de Kahn define el grado de entrada, la cola FIFO y su estrategia análoga a BFS, explica la detección de ciclos y establece el costo $O(|V|+|E|)$. Se agregó a `bibliografia.bib` la referencia primaria `Kahn1962`.
- El algoritmo de Kahn se aplicó al grafo probabilístico mediante una tabla de estados: los grados iniciales son `(0,1,0,2)`, la cola comienza en `[s1,s3]` y la ejecución produce `[1,3,2,4]`, disposición ya mostrada por la Figura 1.2.
- La enumeración exhaustiva se presenta como una ramificación recursiva sobre todos los vértices disponibles de grado cero. El pseudocódigo conserva copias del mapa de grados, la explicación mantiene el costo condicionado por $P$ resultados y el peor caso $P=n!$.
- Se agregó una figura TikZ con el árbol completo del ejemplo: una invocación inicial, 15 llamadas recursivas, 16 estados totales y cinco hojas correspondientes a los candidatos. Cada estado muestra el prefijo emitido y el subgrafo inducido por los vértices restantes.
- La tabla de candidatos quedó reducida a las columnas `Candidato` y `Reordenamiento`; los costos se reservaron para `Evaluación y Selección de Candidatos`.
- El informe compiló correctamente con `latexmk` y quedó en 68 páginas, sin referencias o citas indefinidas ni desbordes nuevos en Solución. La inspección visual de las páginas 36--39 confirmó la legibilidad de la tabla de Kahn, el pseudocódigo, el árbol y la tabla final.

## 2026-08-01

- Se agregó bajo `scripts/setup-latex/` un entorno de instalación nativa para CachyOS compuesto por un manifiesto de paquetes, un instalador, un desinstalador seguro y un verificador independiente para las dependencias de compilación del informe.
- El verificador confirmó mediante una compilación temporal que pdfLaTeX, BibTeX, TikZ, Babel en español, `listings`, las fuentes y los demás paquetes usados por `main.tex` están disponibles, sin modificar los archivos ni artefactos del informe.
