# Mapa tecnico de ApplicativeDo en GHC

Este documento describe, de forma exhaustiva, donde vive y como fluye
`ApplicativeDo` en el submodulo `vendor/ghc`.

Baseline de este mapa:

- submodulo `vendor/ghc` en commit `0b36e96cb93db71f201aaa055c4a90b75a8110ef`

---

## Panorama actual

- `ApplicativeDo` no cambia la sintaxis del parser: cambia el plan interno del
  `do` despues del renombrado.
- El rearrangement ocurre en `GHC.Rename.Expr` y produce `ApplicativeStmt`.
- El typechecker entiende `ApplicativeStmt` en `GHC.Tc.Gen.Match`.
- El desugar final de `ApplicativeStmt` vive en `GHC.HsToCore.Expr`.
- El `do` normal (sin `ApplicativeDo`) hoy se expande en
  `GHC.Tc.Gen.Do` antes del typechecking, no en el desugarer clasico.
- `-foptimal-applicative-do` activa algoritmo optimo `O(n^3)`; el default usa
  heuristica `O(n^2)`.

---

## 1) Inventario completo de rutas relevantes

### 1.1 Entrada de lenguaje y flags

- `vendor/ghc/libraries/ghc-internal/src/GHC/Internal/LanguageExtensions.hs`
  - enum `Extension` contiene `ApplicativeDo`.
- `vendor/ghc/compiler/GHC/Driver/Flags.hs`
  - mapea `LangExt.ApplicativeDo -> "ApplicativeDo"`.
  - define `Opt_OptimalApplicativeDo`.
- `vendor/ghc/compiler/GHC/Driver/Session.hs`
  - registra `-foptimal-applicative-do`.

### 1.2 Parser y construccion inicial de `do`

- `vendor/ghc/compiler/GHC/Parser.y`
  - reglas `DO stmtlist`, `MDO stmtlist`, `qual`, `stmtlist`.
  - `qual` crea `BindStmt` con `mkPsBindStmt` o `BodyStmt` con `mkBodyStmt`.
- `vendor/ghc/compiler/GHC/Parser/PostProcess.hs`
  - `mkHsDoPV` construye `HsDo` para expresiones y comandos.
- `vendor/ghc/compiler/GHC/Hs/Utils.hs`
  - constructores `mkHsDo`, `mkBodyStmt`, `mkLastStmt`, `mkPsBindStmt`.

### 1.3 Renamer (nucleo de ApplicativeDo)

- `vendor/ghc/compiler/GHC/Rename/Expr.hs`
  - `rnExpr (HsDo ...)`.
  - `rnStmtsWithFreeVars` (anota `Stmt` con `FreeVars`).
  - `postProcessStmtsForApplicativeDo` (gate principal por extension/contexto).
  - `rearrangeForApplicativeDo` (algoritmo principal).
  - `mkStmtTreeHeuristic` / `mkStmtTreeOptimal`.
  - `segments`, `splitSegment`, `slurpIndependentStmts`.
  - `stmtTreeToStmts`, `mkApplicativeStmt`, `needJoin`, `isReturnApp`.
  - notas clave:
    - `Note [ApplicativeDo]`
    - `Note [ApplicativeDo and strict patterns]`
    - `Note [ApplicativeDo and refutable patterns]`
    - `Note [Deterministic ApplicativeDo and RecursiveDo desugaring]`

### 1.4 AST y representacion intermedia

- `vendor/ghc/compiler/Language/Haskell/Syntax/Expr.hs`
  - `StmtLR` y `LastStmt` (`Maybe Bool` para `return` strippeado).
  - `FailOperator`.
  - `Note [Applicative BodyStmt]`.
- `vendor/ghc/compiler/GHC/Hs/Expr.hs`
  - define `ApplicativeStmt` y `ApplicativeArg`.
  - `pprStmt` y aplanado para ocultar internals en errores.
  - `XXStmtLR` en `GhcRn`/`GhcTc` usa `ApplicativeStmt`.
- `vendor/ghc/compiler/GHC/Hs/Utils.hs`
  - `collectStmtBinders` contempla `ApplicativeStmt`.
  - `lStmtsImplicits` recorre `ApplicativeStmt` para wildcard binders.

### 1.5 Typechecker, zonker y desugarer

- `vendor/ghc/compiler/GHC/Tc/Gen/Expr.hs`
  - `tcExpr (HsDo ...) = tcDoStmts ...`.
- `vendor/ghc/compiler/GHC/Tc/Gen/Match.hs`
  - `tcDoStmts` y `tcDoStmt`.
  - caso `XStmtLR (ApplicativeStmt ...)`.
  - `tcApplicativeStmts`.
  - `Note [typechecking ApplicativeStmt]`.
  - `Note [ApplicativeDo and constraints]`.
- `vendor/ghc/compiler/GHC/Tc/Zonk/Type.hs`
  - zonk de `ApplicativeStmt`/`ApplicativeArg`.
- `vendor/ghc/compiler/GHC/HsToCore/Expr.hs`
  - `dsDo` caso `ApplicativeStmt`.
- `vendor/ghc/compiler/GHC/HsToCore/Utils.hs`
  - `dsHandleMonadicFailure` (incluye comportamiento para path applicative).

### 1.6 Invariantes y consumidores auxiliares

- `vendor/ghc/compiler/GHC/Tc/Gen/Do.hs`
  - `expand_do_stmts` hace `panic` si ve `ApplicativeStmt`.
- `vendor/ghc/compiler/GHC/HsToCore/ListComp.hs`
  - `panic` para `ApplicativeStmt` en list/monad comp desugaring.
- `vendor/ghc/compiler/GHC/HsToCore/GuardedRHSs.hs`
  - `panic` para `ApplicativeStmt` en guards.
- `vendor/ghc/compiler/GHC/HsToCore/Pmc/Desugar.hs`
  - `panic` para `ApplicativeStmt` en guard desugaring del checker.
- `vendor/ghc/compiler/GHC/HsToCore/Ticks.hs`
  - cobertura/ticks soportan `ApplicativeStmt`/`ApplicativeArg`.
- `vendor/ghc/compiler/GHC/Iface/Ext/Ast.hs`
  - export a HIE AST de `ApplicativeStmt`/`ApplicativeArg`.
- `vendor/ghc/compiler/GHC/Hs/Instances.hs`
  - instancias `Data` para `ApplicativeStmt` y `ApplicativeArg`.

### 1.7 Documentacion oficial en el arbol de GHC

- `vendor/ghc/docs/users_guide/exts/applicative_do.rst`
  - semantica de usuario, complejidad heuristica/optima, patrones estrictos,
    pitfalls.
- `vendor/ghc/docs/users_guide/exts/qualified_do.rst`
  - interaccion de `QualifiedDo` con `<$>`, `<*>`, `join`.

---

## 2) Pipeline real (paso a paso)

```text
Fuente Haskell
  |
  v
Parser (GHC/Parser.y + PostProcess)
  - Crea HsDo con [BindStmt/BodyStmt/LetStmt/RecStmt]
  - Aun no hay ApplicativeStmt
  |
  v
Renamer (GHC.Rename.Expr.rnExpr)
  - rnStmtsWithFreeVars
  - postProcessStmtsForApplicativeDo (si -XApplicativeDo y DoExpr)
  - rearrangeForApplicativeDo -> inserta XStmtLR(ApplicativeStmt)
  |
  v
Typechecker (GHC.Tc.Gen.Match)
  - tcDoStmts decide:
    * con ApplicativeDo: typecheck directo de Stmts (incluye ApplicativeStmt)
    * sin ApplicativeDo: expansion previa a (>>=)/(>>) via GHC.Tc.Gen.Do
  |
  v
Zonker (GHC.Tc.Zonk.Type)
  - zonk de tipos/ops/patrones dentro de ApplicativeStmt
  |
  v
Desugar (GHC.HsToCore.Expr.dsDo)
  - caso ApplicativeStmt => (<$>), (<*>), join opcional
  - casos BindStmt/BodyStmt/LetStmt/RecStmt tambien cubiertos
  |
  v
Core
```

### 2.1 Diferencia clave con `do` normal

- En GHC actual, `do` normal se expande temprano en `GHC.Tc.Gen.Do`
  cuando `-XApplicativeDo` no esta activo para ese `DoExpr`.
- En cambio, para `ApplicativeDo`, el compilador preserva una forma estructural
  (`ApplicativeStmt`) durante renamer/typechecker/zonker y desugar final.

---

## 3) Entrada y gating de `ApplicativeDo`

### 3.1 Deteccion en renamer

`postProcessStmtsForApplicativeDo` (`GHC.Rename.Expr`) aplica la
transformacion solo si:

1. `xoptM LangExt.ApplicativeDo` esta activo.
2. El contexto es `DoExpr` (no list comp, no otros contextos).
3. No estamos dentro de bracket TH (`in_th_bracket`), porque
   `GHC.HsToCore.Quote` no soporta `ApplicativeDo`.

Si no se cumple, usa `noPostProcessStmts` y remueve solo anotaciones de FVs.

### 3.2 `tcDoStmts` y modos

En `GHC.Tc.Gen.Match.tcDoStmts`:

- `DoExpr` + `ApplicativeDo ON`:
  - typecheck de `Stmt` directo (`tcStmts ... tcDoStmt ...`).
- `DoExpr` + `ApplicativeDo OFF`:
  - `expandDoStmts` (expansion a binds/thens) en `GHC.Tc.Gen.Do`.
- `MDoExpr`:
  - expansion por `expandDoStmts` (camino de recursive do).
- `ListComp` y `MonadComp` usan caminos propios (`tcLcStmt`/`tcMcStmt`).

---

## 4) Estructuras de datos (cada elemento)

### 4.1 `StmtLR` y `LastStmt`

En `Language/Haskell/Syntax/Expr.hs`:

- `StmtLR` incluye `XStmtLR` para extensiones por fase.
- `LastStmt ... (Maybe Bool) ...`:
  - `Just True`: se strippeo `return $ e`.
  - `Just False`: se strippeo `return e`.
  - `Nothing`: no hubo stripping.

Ese bit permite reconstruir mejor mensajes de error (forma fuente).

### 4.2 `ApplicativeStmt`

En `GHC.Hs.Expr`:

```haskell
ApplicativeStmt
  (XApplicativeStmt idL idR)
  [(SyntaxExpr idR, ApplicativeArg idL)]
  (Maybe (SyntaxExpr idR))
```

Significado campo por campo:

1. `XApplicativeStmt`:
   - `GhcPs`: `NoExtField`
   - `GhcRn`: `NoExtField`
   - `GhcTc`: `Type` (tipo del body)
2. Lista de pares `(op, arg)`:
   - semantica esperada: `(<$>, arg1), (<*>, arg2), ...`.
3. `Maybe join`:
   - `Just joinOp` si se necesita aplanar `m (m a) -> m a`.

### 4.3 `ApplicativeArg`

Dos variantes:

1. `ApplicativeArgOne`
   - representa una sola sentencia (`BindStmt` o `BodyStmt`).
   - campos:
     - `xarg_app_arg_one`: `FailOperator` tras renombrado/typecheck.
     - `app_arg_pattern`: patron (wildcard para `BodyStmt`).
     - `arg_expr`: RHS.
     - `is_body_stmt`: `True` si originalmente era `BodyStmt`.

2. `ApplicativeArgMany`
   - representa bloque anidado: `do { stmts; return vars }`.
   - campos:
     - `app_stmts`: sentencias del sub-bloque.
     - `final_expr`: expresion final (return/pure o tupla equivalente).
     - `bv_pattern`: patron de variables exportadas al padre.
     - `stmt_context`: contexto de `do` para ppr correcto.

### 4.4 Familias de tipo por fase

- `XApplicativeArgOne`:
  - `GhcPs`: `NoExtField`
  - `GhcRn`: `FailOperator GhcRn`
  - `GhcTc`: `FailOperator GhcTc`
- `XApplicativeArgMany`: `NoExtField`

### 4.5 Pretty-printing y ocultamiento de internals

`GHC.Hs.Expr.pprStmt`:

- En estilo de usuario (`userStyle`), aplana `ApplicativeStmt` a secuencia de
  sentencias originales (`flattenArg`) para no mostrar `<$>`/`<*>` internos.
- En debug style, imprime forma applicative y marca `[join]` si aplica.

---

## 5) Rearrangement en renamer

### 5.1 Entrada: FVs por sentencia

`rnStmtsWithFreeVars` produce `[(Stmt, FreeVars)]`.

- Esto permite analisis de dependencias def-use.
- `collectStmtBinders` (en `GHC.Hs.Utils`) aporta `bv`.

### 5.2 Caso trivial de una sentencia

`rearrangeForApplicativeDo ctxt [(one,_)]`:

- busca nombres de `return` y `pure` respetando `QualifiedDo`.
- llama `needJoin` para detectar si puede convertir `return` a `pure`.
- si no requiere `join`, puede devolver variante simplificada.

### 5.3 Arbol de plan (`StmtTree`)

Tipo interno:

- `StmtTreeOne a`
- `StmtTreeBind left right`
- `StmtTreeApplicative [subtrees]`

Generadores:

1. `mkStmtTreeHeuristic` (`O(n^2)`)
2. `mkStmtTreeOptimal` (`O(n^3)`, DP) si `-foptimal-applicative-do`

Costos en algoritmo optimo:

- nodo bind: suma `c1 + c2`.
- nodo applicative: `maximum` de costos de ramas (modelo de paralelismo).

### 5.4 Segmentacion por independencia

`segments` divide secuencias usando FVs/BVs:

- construye `allvars` de todos los binders del bloque.
- recorre de atras hacia adelante (`walk/chunter`).
- corta segmentos cuando conjunto de dependencias queda vacio.
- evita separar `LetStmt` en segmento aislado cuando puede fusionarlo con el
  siguiente (`merge`), para no forzar `Monad` innecesario.

### 5.5 Split heuristico dentro de segmento indivisible

`splitSegment` usa `slurpIndependentStmts`:

- intenta mover un prefijo independiente para insertar bind en buen lugar.
- distingue `LetStmt` y `BindStmt` para mejorar agrupacion.
- protege contra loop infinito (`#14163`) asegurando que el split sea real.

### 5.6 Patrones estrictos y lazyness

`definitelyLazyPattern` (analisis conservador):

- `True` para casos claramente perezosos (`VarPat`, `LazyPat`, etc).
- `False` en caso de duda (`ConPat`, `TuplePat`, `BangPat`, etc).

Regla:

- si el patron no es definitivamente perezoso, se fuerza dependencia con
  la sentencia siguiente para no cambiar strictness semantica.

### 5.7 Patrones refutables y decision de `join`

En `stmtTreeToStmts`:

- `hasRefutablePattern` detecta patrones refutables (usa
  `isIrrefutableHsPat`, `-XStrict`, COMPLETE pragmas).
- si hay patron refutable en algun argumento applicative, se fuerza `join`
  para que los tipos y `fail` monadico cierren correctamente.

### 5.8 Construccion final de `ApplicativeStmt`

`mkApplicativeStmt`:

- resuelve operadores con `lookupQualifiedDoStmtName`:
  - `fmapName` (`<$>`)
  - `apAName` (`<*>`)
  - `joinMName` (si `need_join=True`)
- crea nodo `XStmtLR (ApplicativeStmt ...)`.
- deja cola (`body_stmts`) luego del nodo applicative.

### 5.9 `needJoin` / `isReturnApp` (normalizacion de cola)

`needJoin` decide dos cosas:

1. si hay que aplicar `join`.
2. si hay que strippear `return/pure` del `LastStmt` o reemplazar por `pure`.

Formas reconocidas por `isReturnApp`:

- `return e`, `return $ e`, `pure e`, `pure $ e`
- con parentesis y `HsAppType` envolviendo variable.

Si no reconoce forma exacta, se mantiene camino monadico (`join`/bind).

---

## 6) Typechecking de `ApplicativeStmt`

### 6.1 Entrada especial en `tcDoStmt`

Caso:

```haskell
tcDoStmt ctxt (XStmtLR (ApplicativeStmt _ pairs mb_join)) ...
```

Flujo:

1. typecheck de args+ops via `tcApplicativeStmts`.
2. si `mb_join = Just join_op`, typecheck de `join_op` con `tcSyntaxOp`.
3. salida: `ApplicativeStmt body_ty pairs' mb_join'`.

### 6.2 `tcApplicativeStmts` (internos)

`tcApplicativeStmts ctxt pairs rhs_ty thing_inside`:

1. crea vars frescas de tipo:
   - `exp_tys`, `pat_tys`, intermedios `t_i`, `body_ty`.
2. typecheck de operadores primero (`goOps`) para mejorar errores de
   rebindable syntax.
3. typecheck de cada `ApplicativeArg` por separado (`goArg`).
4. extiende entorno con binders de todos los args y ejecuta `thing_inside`.

### 6.3 Regla de constraints entre ramas

`Note [ApplicativeDo and constraints]`:

- constraints de una rama applicative no deben resolver constraints de otra
  rama hermana.
- cada `argi` se typecheckea aislado.
- luego se ponen en scope solo los binders (terminos) para el `thing_inside`.

### 6.4 Contexto de error

`tcStmtsAndThen` evita envolver `ApplicativeStmt` con `StmtErrCtxt` extra,
para no degradar diagnosticos (regresion historica `ado002`).

---

## 7) Zonk

`GHC.Tc.Zonk.Type.zonkStmt` tiene caso dedicado para `ApplicativeStmt`.

Detalles importantes:

- zonkea `join` (si existe), operadores y tipos del body.
- orden de scope documentado en codigo:
  - `join > ops (reverse) > pats (forward) > rest`.
- `zonk_args_rev` va en reversa para manejar skolems de operadores
  potencialmente higher-rank.

---

## 8) Desugar final a Core

### 8.1 `dsDo` en `GHC.HsToCore.Expr`

Caso clave:

```haskell
go _ (XStmtLR (ApplicativeStmt body_ty args mb_join)) stmts
```

Flujo de desugar:

1. convierte cada arg:
   - `ApplicativeArgOne`: desugarea `arg_expr`.
   - `ApplicativeArgMany`: ejecuta `dsDo` recursivo en subbloque.
2. desugarea `body` restante como `HsDo`.
3. construye lambda sobre patrones con `matchSinglePatVar` y
   `dsHandleMonadicFailure`.
4. pliega llamadas applicative con operadores (`<$>`, `<*>`).
5. aplica `join` si `mb_join` es `Just`.

### 8.2 Fallo de patrones

`GHC.HsToCore.Utils.dsHandleMonadicFailure`:

- en path applicative, si hay `fail_op`, llama fail monadico.
- en casos especiales sin `fail_op` pero match fallible, puede usar error app
  (caso defensivo, con assert de irrefutabilidad cuando corresponde).

---

## 9) Invariantes de forma (quien puede ver `ApplicativeStmt`)

`ApplicativeStmt` esta pensado para `do` expressions, no para otros contextos.

Evidencia en codigo (panic defensivo):

- `GHC.Tc.Gen.Do.expand_do_stmts`: panic en `ApplicativeStmt`.
- `GHC.HsToCore.ListComp`: panic en list/monad comp paths.
- `GHC.HsToCore.GuardedRHSs`: panic en guards.
- `GHC.HsToCore.Pmc.Desugar`: panic en desugar de guards para checker.

Interpretacion:

- si `ApplicativeStmt` aparece fuera del camino esperado, es bug de
  fases anteriores.

---

## 10) Interaccion con `QualifiedDo` y `RebindableSyntax`

### 10.1 Resolucion de nombres

- `GHC.Rename.Env.lookupQualifiedDoName`
- `GHC.Rename.Env.lookupQualifiedDo`
- `GHC.Rename.Expr.lookupQualifiedDoStmtName`

Regla:

- si el bloque es `M.do`, busca operadores calificados en `M`.
- si no, aplica logica normal de rebindable syntax.

### 10.2 Operadores usados por `ApplicativeDo`

`ApplicativeDo` puede requerir:

- `fmap` (`<$>`)
- `<*>`
- `join` (opcional)
- `return` / `pure` (deteccion/normalizacion de cola)
- `fail` (si hay patrones refutables)

Todo esto se resuelve en renamer/typechecker segun contexto.

---

## 11) Preservacion de errores y UX del compilador

Mecanismos principales:

1. `LastStmt` guarda marca de `return` strippeado (`Maybe Bool`).
2. `pprStmt` aplana `ApplicativeStmt` en modo usuario.
3. `tcStmtsAndThen` evita contexto de error extra en `ApplicativeStmt`.

Resultado:

- internamente se optimiza/reestructura, externamente los errores siguen
  pareciendo sobre el `do` original.

---

## 12) Tooling y metadatos (mas alla del pipeline core)

- HIE AST:
  - `GHC.Iface.Ext.Ast` serializa `ApplicativeStmt`/`ApplicativeArg`.
- Cobertura/ticks:
  - `GHC.HsToCore.Ticks` recorre y anota `ApplicativeStmt`/`ApplicativeArg`.
- Recoleccion de binders:
  - `GHC.Hs.Utils.collectStmtBinders` y `lStmtsImplicits` cubren
    `ApplicativeStmt`.
- Instancias genericas:
  - `GHC.Hs.Instances` da `Data` para `ApplicativeStmt`/`ApplicativeArg`.

---

## 13) Tests de regresion asociados

Suite principal:

- `vendor/ghc/testsuite/tests/ado/all.T`

Esta suite cubre:

- compilacion y ejecucion de casos basicos (`ado001`, `ado011`, etc),
- preservacion de errores y constraints (`ado002`, `ado003`, `T13242a`, etc),
- patrones estrictos/refutables (`T13875`, `OrPatStrictness`, etc),
- algoritmo optimo (`ado-optimal`),
- casos de regresion historicos (`T12490`, `T14163`, `T20540`, etc).

Suites relacionadas:

- `testsuite/tests/qualifieddo/*` (resolucion de operadores con `M.do`).
