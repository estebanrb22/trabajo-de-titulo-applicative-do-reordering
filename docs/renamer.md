# Flujo del Renamer para `HsDo` y reordenamiento conmutativo

Este documento describe `GHC.Rename.Expr` para expresiones `HsDo`, incluyendo la extensión experimental de la memoria: generación de permutaciones semánticamente válidas para bloques `do` marcados como conmutativos mediante `QualifiedDo`.

## Flujo general

```haskell
rnExpr
  -> rnStmtsWithFreeVars
  -> postProcessStmtsForApplicativeDo
  -> rearrangeForApplicativeDo
       -> isCommutativeQualifiedDo
       -> buildStmtsDependencyGraph
       -> enumerateSemanticTopSortsBounded
       -> mkStmtTreeHeuristic / mkStmtTreeOptimal
       -> selección automática por costo o selección forzada por candidato
       -> stmtTreeToStmts
```

El camino forma parte del Renamer. La transformación final produce `ApplicativeStmt` cuando el plan elegido permite usar operaciones applicative.

## `rnExpr (HsDo ...)`

La entrada relevante para `do`-notation está en `rnExpr`:

```haskell
rnExpr (HsDo _ do_or_lc (L l stmts))
 = do { ((stmts1, _), fvs1) <-
          rnStmtsWithFreeVars (HsDoStmt do_or_lc) rnExpr stmts
            (\ _ -> return ((), emptyFVs))
      ; (pp_stmts, fvs2) <- postProcessStmtsForApplicativeDo do_or_lc stmts1
      ; return ( HsDo noExtField do_or_lc (L l pp_stmts), fvs1 `plusFV` fvs2 ) }
```

`rnStmtsWithFreeVars` renombra cada statement y conserva sus `FreeVars`. Esa información es la base para construir dependencias locales entre statements.

## `postProcessStmtsForApplicativeDo`

El gate principal de `ApplicativeDo` es:

```haskell
postProcessStmtsForApplicativeDo ctxt stmts
  = do { ado_is_on <- xoptM LangExt.ApplicativeDo
       ; let is_do_expr | DoExpr{} <- ctxt = True
                        | otherwise = False
       ; in_th_bracket <- isBrackLevel <$> getThLevel
       ; if ado_is_on && is_do_expr && not in_th_bracket
             then do { traceRn "ppsfa" (ppr stmts)
                     ; rearrangeForApplicativeDo ctxt stmts }
             else noPostProcessStmts (HsDoStmt ctxt) stmts }
```

Esto significa que el reordenamiento experimental solo puede ejecutarse dentro del flujo normal de `ApplicativeDo`. Si `-XApplicativeDo` no está activo, no se entra a `rearrangeForApplicativeDo`.

El detector conmutativo tiene una rama para `MDoExpr`, pero este gate llama a `rearrangeForApplicativeDo` solo para `DoExpr`. En la práctica, los experimentos conmutativos usan `CD.do`.

## Opt-in conmutativo con `QualifiedDo`

La activación del reordenamiento conmutativo se hace de forma sintáctica y se basa en `QualifiedDo`:

```haskell
commutativeDoMarkerOcc = mkVarOccFS (fsLit "__commutative_do__")

isCommutativeQualifiedDo :: HsDoFlavour -> RnM Bool
isCommutativeQualifiedDo (DoExpr (Just modName)) =
  isJust <$> lookupOccRn_maybe (mkRdrQual modName commutativeDoMarkerOcc)
isCommutativeQualifiedDo (MDoExpr (Just modName)) =
  isJust <$> lookupOccRn_maybe (mkRdrQual modName commutativeDoMarkerOcc)
isCommutativeQualifiedDo _ =
  return False
```

Un bloque `M.do` es considerado conmutativo si el módulo calificador `M` exporta el marcador `__commutative_do__`. El módulo experimental esperado es `Control.Monad.CommutativeDo`, que reexporta ese marcador junto a las operaciones necesarias para `QualifiedDo`.

El compilador no prueba que la mónada sea conmutativa. La clase `CommutativeMonad` es una afirmación del programador y actúa como mecanismo de opt-in.

## Flag de selección de candidato

La flag relacionada con la selección de candidatos es:

```text
-fado-reorder-candidate-n=<n>
```

No activa el reordenamiento. Solo fuerza al Renamer a seleccionar una permutación ya generada, lo que permite validar semánticamente cada candidato.

Implementación en el driver:

```haskell
-- GHC.Driver.DynFlags
adoReorderCandidateN :: Maybe Int

-- defaultDynFlags
adoReorderCandidateN = Nothing

-- GHC.Driver.Session
make_ord_flag defFlag "fado-reorder-candidate-n"
  (intSuffix (\n d -> d { adoReorderCandidateN = Just n }))
```

Si la flag no está presente, el Renamer selecciona automáticamente el candidato de menor costo. Si `n` es negativo o está fuera de rango, se ignora y también se usa la selección automática.

## `rearrangeForApplicativeDo`

El flujo de `rearrangeForApplicativeDo` es:

```haskell
rearrangeForApplicativeDo ctxt stmts0 = do
  optimal_ado <- goptM Opt_OptimalApplicativeDo
  commutative_do <- isCommutativeQualifiedDo ctxt
  reorder_cand_n <- adoReorderCandidateN <$> getDynFlags

  traceRn "rearrangeForADo-commutative-do" $
    vcat [ text "commutative-do =" <+> ppr commutative_do ]

  (all_permutations, validStmtsPerms) <-
    if commutative_do
      then do
        let stmtsDepsGraph = buildStmtsDependencyGraph stmts
        traceStmtDependencyGraph stmtsDepsGraph
        let validStmtsPermsNodes = enumerateSemanticTopSortsBounded stmtsDepsGraph
        let candidates = map depStmtInfosToStmtSeq validStmtsPermsNodes
        return (candidates, validStmtsPermsNodes)
      else
        return ([stmts], [computeStmtsInfo stmts])

  let mkStmtTree | optimal_ado = mkStmtTreeOptimal
                 | otherwise = mkStmtTreeHeuristic

  let stmt_trees = map mkStmtTree all_permutations
  let all_permutations_info =
        zipWith3 mkStmtsPermutationInfo [0 :: Int ..] validStmtsPerms stmt_trees

  when commutative_do $
    traceTopSortCandidates all_permutations_info

  let best_candidate = case nonEmpty all_permutations_info of
          Just cs -> minimumBy (comparing candCost) cs
          Nothing -> panic "rearrangeForApplicativeDo: empty stmt_trees"

  let selected_candidate = do
        i <- reorder_cand_n
        guard (i >= 0)
        listToMaybe (drop i all_permutations_info)

  let final_candidate = fromMaybe best_candidate selected_candidate

  let final_trace_label = case selected_candidate of
        Just _ -> "rearrangeForADo candidate selection tree (fado-reorder-candidate-n) ="
        Nothing -> "rearrangeForADo final tree:"

  traceRnFinalTree final_trace_label final_candidate best_candidate all_permutations_info
```

En el caso no conmutativo solo se considera la lista original de statements. Para mantener un formato uniforme, se crea un candidato técnico con `computeStmtsInfo stmts`. Los scripts de validación presentan este caso como cero permutaciones de reordenamiento, aunque internamente exista el candidato original.

Los candidatos están indexados desde `0`. Los statements conservan índices desde `1`, porque `computeStmtsInfo` usa `zipWith mkStmtInfo [1 ..]`.

## Grafo de precedencia

Cada statement se modela como `StmtDepInfo`:

```haskell
data StmtDepInfo = StmtDepInfo
  { sdiIndex       :: !Int
  , sdiStmt        :: !(ExprLStmt GhcRn)
  , sdiFvsOriginal :: !FreeVars
  , sdiReadsLocal  :: !FreeVars
  , sdiWritesLocal :: !FreeVars
  }
```

La construcción base es:

```haskell
computeStmtsInfo :: [(ExprLStmt GhcRn, FreeVars)] -> [StmtDepInfo]
computeStmtsInfo stmts = zipWith mkStmtInfo [1 ..] stmts
  where
    all_writes =
      mkNameSet (concatMap (collectStmtBinders CollNoDictBinders . unLoc . fst) stmts)

    mkStmtInfo i (stmt, fvs) = StmtDepInfo
      { sdiIndex       = i
      , sdiStmt        = stmt
      , sdiFvsOriginal = fvs
      , sdiReadsLocal  = fvs `intersectNameSet` all_writes
      , sdiWritesLocal = mkNameSet (collectStmtBinders CollNoDictBinders (unLoc stmt))
      }
```

La relación relevante para el Renamer es:

- `WRITE(stmt) = collectStmtBinders CollNoDictBinders stmt`.
- `READ_local(stmt) = fvs(stmt) ∩ all_writes`.
- `RAW(i,j) = WRITE(i) ∩ READ_local(j)`.

El grafo interno solo modela dependencias `RAW`: `buildStmtDepNodes` crea aristas `i -> j` cuando `i < j` y `WRITE(i) ∩ READ_local(j)` no es vacío. El grafo se implementa con `GHC.Data.Graph.Directed`.

Las dependencias `WAR` y `WAW` pertenecen al modelo general de asignaciones imperativas, pero no aparecen como restricciones reales en este nivel de GHC. Después del renombrado, cada binder local corresponde a un `Name` único: no existe sobrescritura de un mismo `Name` renombrado y una lectura solo puede referirse a definiciones en scope. Por eso el criterio interno se reduce a preservar relaciones def-use, es decir, dependencias `RAW`.

## Enumeración de permutaciones

`enumerateSemanticTopSortsBounded` enumera ordenamientos topológicos del grafo:

```haskell
enumerateSemanticTopSortsBounded :: StmtDepGraph -> [[StmtDepInfo]]
```

Cada resultado conserva `StmtDepInfo`, por lo que no se pierde:

- índice original del statement,
- statement renombrado,
- `FreeVars` originales,
- reads/writes locales.

Luego `depStmtInfosToStmtSeq` transforma cada permutación de nodos en una lista de statements apta para `mkStmtTreeHeuristic` o `mkStmtTreeOptimal`.

## Información de candidatos y costos

Para no separar la información de la permutación de su árbol y costo, se usa:

```haskell
data StmtsPermutationInfo = StmtsPermutationInfo
  { candIndex     :: !Int
  , candPerm      :: [StmtDepInfo]
  , candTree      :: ExprStmtTree
  , candCost      :: !Cost
  }

mkStmtsPermutationInfo :: Int -> [StmtDepInfo] -> ExprStmtTree -> StmtsPermutationInfo
mkStmtsPermutationInfo index perm tree =
  StmtsPermutationInfo
    { candIndex     = index
    , candPerm      = perm
    , candTree      = tree
    , candCost      = stmtTreeCost tree
    }
```

La selección automática se hace por costo:

```haskell
best_candidate = minimumBy (comparing candCost) all_permutations_info
```

Si hay empate, `minimumBy` mantiene el primer candidato mínimo encontrado en la lista de candidatos. La selección forzada por `-fado-reorder-candidate-n=i` tiene prioridad sobre el candidato mínimo solo si `i` es válido.

El costo se calcula con:

```haskell
stmtTreeCost :: ExprStmtTree -> Cost
stmtTreeCost (StmtTreeOne _) = 1
stmtTreeCost (StmtTreeBind l r) = stmtTreeCost l + stmtTreeCost r
stmtTreeCost (StmtTreeApplicative ts) =
  case ts of
    [] -> 0
    _  -> Partial.maximum (map stmtTreeCost ts)
```

## Trazas del Renamer

Todas las trazas usan `traceRn`, por lo que aparecen con `-ddump-rn-trace`.

### Estado del opt-in

```text
rearrangeForADo-commutative-do
  commutative-do = True
```

### Grafo de dependencias

```text
rearrangeForADo-StmtsDependencyGraph

rearrangeForADo-dep
  pair           =  1  ->  3
  RAW            =  {x1}
```

### Candidatos de permutación

`traceTopSortCandidates` imprime cada permutación junto a su árbol y costo:

```text
rearrangeForADo-permutation
  candidate   =  0
  index-order =  [1, 2, 3, 4]
  statements  =  [x1 <- Just 10, x2 <- Just 5,
                  x3 <- safeDiv x1 2, x4 <- Just (x2 + 15)]
  rearrangeForADo-resulting tree =
    (StmtTreeBind ...)
  tree-cost =  2
```

### Árbol final seleccionado automáticamente

Cuando no se usa `-fado-reorder-candidate-n`, `traceRnFinalTree` usa la etiqueta:

```text
rearrangeForADo final tree:
  candidate   =  0
  index-order =  [1, 2, 3, 4]
  statements  =  [x1 <- Just 10, x2 <- Just 5,
                  x3 <- safeDiv x1 2, x4 <- Just (x2 + 15)]
  rearrangeForADo-resulting tree =
    (StmtTreeBind ...)
  tree-cost =  2
```

### Árbol seleccionado por flag

Cuando `-fado-reorder-candidate-n=i` selecciona un candidato válido, la etiqueta cambia a:

```text
rearrangeForADo candidate selection tree (fado-reorder-candidate-n) =
  candidate   =  3
  index-order =  [2, 1, 3, 4]
  statements  =  [...]
  rearrangeForADo-resulting tree =
    (StmtTreeApplicative ...)
  tree-cost =  2
```

### Resumen global

El resumen se imprime en la rama general de `rearrangeForApplicativeDo`; los casos especiales de bloque vacío o de un único statement retornan directamente:

```text
rearrangeForADo-Summary:
  minimum-cost-perm-index      =  0
  original-cost                =  4
  applicative-do-cost          =  2
  reorder-and-ado-minimum-cost =  2
  generated-permutations       =  6
  minimum-cost-permutations    =  6
```

Significado de los campos:

- `minimum-cost-perm-index`: índice base cero del candidato de menor costo.
- `original-cost`: costo secuencial base, calculado como la cantidad de statements previos al `LastStmt`.
- `applicative-do-cost`: costo de aplicar `ApplicativeDo` al orden original.
- `reorder-and-ado-minimum-cost`: menor costo obtenido entre todas las permutaciones semánticamente válidas.
- `generated-permutations`: cantidad de candidatos técnicos considerados.
- `minimum-cost-permutations`: cantidad de candidatos que empatan con el costo mínimo.

## Generadores de árboles

`ExprStmtTree` representa el plan de ejecución:

```haskell
data StmtTree a
  = StmtTreeOne a
  | StmtTreeBind (StmtTree a) (StmtTree a)
  | StmtTreeApplicative [StmtTree a]

type ExprStmtTree = StmtTree (ExprLStmt GhcRn, FreeVars)
```

Los generadores disponibles son:

- `mkStmtTreeHeuristic`: algoritmo heurístico `O(n^2)`.
- `mkStmtTreeOptimal`: algoritmo óptimo `O(n^3)`, activado por `-foptimal-applicative-do`.

## Reconstrucción a statements

Después de elegir `final_candidate`, `stmtTreeToStmts` reconstruye la lista final de statements insertando `ApplicativeStmt` cuando corresponde. Esa parte conserva la semántica existente de `ApplicativeDo`, incluyendo manejo de `pure`, `return`, `join`, patrones estrictos y patrones refutables.

## Módulos de soporte para `QualifiedDo`

El opt-in conmutativo esperado en experimentos es:

```haskell
{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

example :: Maybe Int
example = CD.do
  x <- Just 1
  y <- Just 2
  CD.return (x + y)
```

Módulos de soporte en GHC:

- `vendor/ghc/libraries/ghc-internal/src/GHC/Internal/Control/Monad/CommutativeDo.hs`: define `CommutativeMonad`, `__commutative_do__` y las operaciones requeridas por `QualifiedDo`.
- `vendor/ghc/libraries/base/src/Control/Monad/CommutativeDo.hs`: módulo público que reexporta el módulo interno.

## Archivos relacionados

- `vendor/ghc/compiler/GHC/Rename/Expr.hs`: implementación principal.
- `vendor/ghc/compiler/GHC/Driver/DynFlags.hs`: define `adoReorderCandidateN :: Maybe Int`.
- `vendor/ghc/compiler/GHC/Driver/Session.hs`: registra `-fado-reorder-candidate-n`.
- `vendor/ghc/libraries/ghc-internal/src/GHC/Internal/Control/Monad/CommutativeDo.hs`: marcador interno `__commutative_do__` y operaciones para `QualifiedDo`.
- `vendor/ghc/libraries/base/src/Control/Monad/CommutativeDo.hs`: módulo público para usar el opt-in desde experimentos.
