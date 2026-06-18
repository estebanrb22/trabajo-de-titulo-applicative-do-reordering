# Flujo del Renamer para `HsDo` y reordenamiento conmutativo

Este documento describe el flujo actual de `GHC.Rename.Expr` para expresiones
`HsDo`, incluyendo la extensión experimental de la memoria: generación de
permutaciones semánticamente válidas para bloques `do` marcados como
conmutativos mediante `QualifiedDo`.

## Flujo General

```haskell
rnExpr
  -> rnStmtsWithFreeVars
  -> postProcessStmtsForApplicativeDo
  -> rearrangeForApplicativeDo
       -> isCommutativeQualifiedDo
       -> buildStmtsDependencyGraph
       -> enumerateSemanticTopSortsBounded
       -> mkStmtTreeHeuristic / mkStmtTreeOptimal
       -> stmtTreeToStmts
```

El camino sigue siendo parte del Renamer. La transformación final produce
`ApplicativeStmt` cuando el plan elegido permite usar operaciones applicative.

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

`rnStmtsWithFreeVars` renombra cada statement y conserva sus `FreeVars`. Esa
información es la base para construir dependencias locales entre statements.

## `postProcessStmtsForApplicativeDo`

El gate principal de `ApplicativeDo` sigue siendo:

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

Esto significa que el reordenamiento experimental solo puede ejecutarse dentro
del flujo normal de `ApplicativeDo`. Si `-XApplicativeDo` no está activo, no se
entra a `rearrangeForApplicativeDo`.

## Opt-in Conmutativo Con `QualifiedDo`

La activación del reordenamiento conmutativo ya no depende de una flag general
`-freorder-commutative-monads-ado`. Esa flag fue eliminada del conjunto de
`GeneralFlag` y de `fFlagsDeps`.

El opt-in ahora es sintáctico y se basa en `QualifiedDo`:

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

Un bloque `M.do` es considerado conmutativo si el módulo calificador `M` exporta
el marcador `__commutative_do__`. El módulo experimental esperado es
`Control.Monad.CommutativeDo`, que reexporta ese marcador junto a las operaciones
necesarias para `QualifiedDo`.

## `rearrangeForApplicativeDo`

El flujo actual de `rearrangeForApplicativeDo` es:

```haskell
rearrangeForApplicativeDo ctxt stmts0 = do
  optimal_ado <- goptM Opt_OptimalApplicativeDo
  commutative_do <- isCommutativeQualifiedDo ctxt

  traceRn "rearrangeForADo-commutative-do" $
    vcat [ text "commutative-do    =" <+> ppr commutative_do ]

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
        zipWith3 mkStmtsPermutationInfo [1 :: Int ..] validStmtsPerms stmt_trees

  when commutative_do $
    traceTopSortCandidates all_permutations_info

  let best_candidate = case nonEmpty all_permutations_info of
          Just cs -> minimumBy (comparing candCost) cs
          Nothing -> panic "rearrangeForApplicativeDo: empty stmt_trees"

  let best_tree = candTree best_candidate

  traceRnFinalTree best_candidate all_permutations_info
```

En el caso no conmutativo se preserva el comportamiento base: solo se considera
la lista original de statements. Para mantener un formato uniforme, se crea una
permutación artificial con `computeStmtsInfo stmts`.

## Grafo de Precedencia

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

La relación con las reglas clásicas de dependencias es:

- `WRITE(stmt) = collectStmtBinders CollNoDictBinders stmt`.
- `READ_local(stmt) = fvs(stmt) ∩ all_writes`.
- `RAW(i,j) = WRITE(i) ∩ READ_local(j)`.
- `WAR(i,j) = READ_local(i) ∩ WRITE(j)`.
- `WAW(i,j) = WRITE(i) ∩ WRITE(j)`.

`buildStmtDepNodes` crea aristas `i -> j` cuando `i < j` y existe alguna de las
dependencias anteriores. El grafo se implementa con `GHC.Data.Graph.Directed`.

## Enumeración de Permutaciones

`enumerateSemanticTopSortsBounded` enumera ordenamientos topológicos del grafo:

```haskell
enumerateSemanticTopSortsBounded :: StmtDepGraph -> [[StmtDepInfo]]
```

Cada resultado conserva `StmtDepInfo`, por lo que no se pierde:

- índice original del statement,
- statement renombrado,
- `FreeVars` originales,
- reads/writes locales.

Luego `depStmtInfosToStmtSeq` transforma cada permutación de nodos en una lista
de statements apta para `mkStmtTreeHeuristic` o `mkStmtTreeOptimal`.

## Información de Candidatos y Costos

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

La selección final se hace por costo:

```haskell
best_candidate = minimumBy (comparing candCost) all_permutations_info
best_tree = candTree best_candidate
```

Si hay empate, `minimumBy` mantiene el primer candidato mínimo encontrado en la
lista de candidatos.

## Trazas del Renamer

Todas las trazas usan `traceRn`, por lo que aparecen con `-ddump-rn-trace`.

### Estado del opt-in

```text
rearrangeForADo-commutative-do
  commutative-do    = True
```

### Grafo de dependencias

```text
rearrangeForADo-StmtsDependencyGraph

rearrangeForADo-dep
  pair           =  1  ->  3
  RAW            =  {x1}
  WAR            =  {}
  WAW            =  {}
```

### Candidatos de permutación

`traceTopSortCandidates` imprime cada permutación junto a su árbol y costo:

```text
rearrangeForADo-permutation
  candidate   =  5
  index order =  [2, 1, 4, 3]
  statements  =  [x2 <- Just 5, x1 <- Just 10,
                  x4 <- Just (x2 + 15), x3 <- safeDiv x1 2]
  rearrangeForADo-resulting tree =
    (StmtTreeBind ...)
  actual cost =  2
```

### Árbol final seleccionado

`traceRnFinalTree` imprime la metadata del candidato seleccionado y métricas
globales:

```text
rearrangeForADo final tree:
  candidate   =  1
  index order =  [1, 2, 3, 4]
  statements  =  [x1 <- Just 10, x2 <- Just 5,
                  x3 <- safeDiv x1 2, x4 <- Just (x2 + 15)]
  rearrangeForADo-resulting tree =
    (StmtTreeBind ...)
  original-cost             =  2
  minimum-cost              =  2
  generated permutations    =  6
  minimum-cost permutations =  6
```

`original-cost` corresponde al costo del primer candidato de
`all_permutations_info`, que representa el orden original. `minimum-cost` es el
costo de `best_candidate`. `minimum-cost permutations` cuenta cuántos candidatos
tienen ese mismo costo mínimo.

## Generadores de Árboles

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
- `mkStmtTreeOptimal`: algoritmo óptimo `O(n^3)`, activado por
  `-foptimal-applicative-do`.

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

## Reconstrucción a Statements

Después de elegir `best_tree`, `stmtTreeToStmts` reconstruye la lista final de
statements insertando `ApplicativeStmt` cuando corresponde. Esa parte conserva
la semántica existente de `ApplicativeDo`, incluyendo manejo de `pure`, `return`,
`join`, patrones estrictos y patrones refutables.

## Archivos Relacionados

- `vendor/ghc/compiler/GHC/Rename/Expr.hs`: implementación principal.
- `vendor/ghc/compiler/GHC/Driver/Flags.hs`: ya no define
  `Opt_ReorderCommutativeMonadsAdo`.
- `vendor/ghc/compiler/GHC/Driver/Session.hs`: ya no registra
  `-freorder-commutative-monads-ado`.
- `vendor/ghc/libraries/ghc-internal/src/GHC/Internal/Control/Monad/CommutativeDo.hs`:
  marcador interno `__commutative_do__` y operaciones para `QualifiedDo`.
- `vendor/ghc/libraries/base/src/Control/Monad/CommutativeDo.hs`: módulo público
  para usar el opt-in desde experimentos.
