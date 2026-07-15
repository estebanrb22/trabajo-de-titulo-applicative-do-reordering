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
