# Flujo de ejecución de Renamer en `GHC.Rename.Expr` con `HsDo` expression

Funciones que se invocan a lo largo del flujo de renombrado de una expression de Haskell de tipo `HsDo`:

``` haskell
-> rnExpr 
-> rnStmtsWithFreeVars 
-> postProcessStmtsForApplicativeDo 
-> rearrangeForApplicativeDo
  -> mkStmtTreeOptimal
  -> mkStmtTreeHeuristic
```

# Definiciones de cada función:

## RnExpr

``` haskell
rnExpr :: HsExpr GhcPs -> RnM (HsExpr GhcRn, FreeVars)

rnExpr (HsDo _ do_or_lc (L l stmts))
 = do { ((stmts1, _), fvs1) <-
          rnStmtsWithFreeVars (HsDoStmt do_or_lc) rnExpr stmts
            (\ _ -> return ((), emptyFVs))
      ; (pp_stmts, fvs2) <- postProcessStmtsForApplicativeDo do_or_lc stmts1
      ; return ( HsDo noExtField do_or_lc (L l pp_stmts), fvs1 `plusFV` fvs2 ) }
```

## rnStmtsWithFreeVars

``` haskell
rnStmtsWithFreeVars :: AnnoBody body
        => HsStmtContextRn
        -> ((body GhcPs) -> RnM ((body GhcRn), FreeVars))
        -> [LStmt GhcPs (LocatedA (body GhcPs))]
        -> ([Name] -> RnM (thing, FreeVars))
        -> RnM ( ([(LStmt GhcRn (LocatedA (body GhcRn)), FreeVars)], thing)
               , FreeVars)
-- Each Stmt body is annotated with its FreeVars, so that
-- we can rearrange statements for ApplicativeDo.
--
-- Variables bound by the Stmts, and mentioned in thing_inside,
-- do not appear in the result FreeVars

rnStmtsWithFreeVars ctxt _ [] thing_inside
  = do { checkEmptyStmts ctxt
       ; (thing, fvs) <- thing_inside []
       ; return (([], thing), fvs) }

rnStmtsWithFreeVars mDoExpr@(HsDoStmt MDoExpr{}) rnBody (nonEmpty -> Just stmts) thing_inside    
-- Deal with mdo
  = -- Behave like do { rec { ...all but last... }; last }
    do { ((stmts1, (stmts2, thing)), fvs)
           <- rnStmt mDoExpr rnBody (noLocA $ mkRecStmt noAnn (noLocA (NE.init stmts))) $ \ _ ->
              do { last_stmt' <- checkLastStmt mDoExpr (NE.last stmts)
                 ; rnStmt mDoExpr rnBody last_stmt' thing_inside }
        ; return (((stmts1 ++ stmts2), thing), fvs) }

rnStmtsWithFreeVars ctxt rnBody (lstmt@(L loc _) : lstmts) thing_inside
  | null lstmts
  = setSrcSpanA loc $
    do { lstmt' <- checkLastStmt ctxt lstmt
       ; rnStmt ctxt rnBody lstmt' thing_inside }

  | otherwise
  = do { ((stmts1, (stmts2, thing)), fvs)
            <- setSrcSpanA loc                  $
               do { checkStmt ctxt lstmt
                  ; rnStmt ctxt rnBody lstmt $ \ bndrs1 ->
                    rnStmtsWithFreeVars ctxt rnBody lstmts  $ \ bndrs2 ->
                    thing_inside (bndrs1 ++ bndrs2) }
        ; return (((stmts1 ++ stmts2), thing), fvs) }
```

## postProcessStmtsForApplicativeDo

``` haskell
-- | maybe rearrange statements according to the ApplicativeDo transformation
postProcessStmtsForApplicativeDo
  :: HsDoFlavour
  -> [(ExprLStmt GhcRn, FreeVars)]
  -> RnM ([ExprLStmt GhcRn], FreeVars)
postProcessStmtsForApplicativeDo ctxt stmts
  = do {
       -- rearrange the statements using ApplicativeStmt if
       -- -XApplicativeDo is on.  Also strip out the FreeVars attached
       -- to each Stmt body.
         ado_is_on <- xoptM LangExt.ApplicativeDo
       ; let is_do_expr | DoExpr{} <- ctxt = True
                        | otherwise = False
       -- don't apply the transformation inside TH brackets, because
       -- GHC.HsToCore.Quote does not handle ApplicativeDo.
       ; in_th_bracket <- isBrackLevel <$> getThLevel
       ; if ado_is_on && is_do_expr && not in_th_bracket
            then do { traceRn "ppsfa" (ppr stmts)
                    ; rearrangeForApplicativeDo ctxt stmts }
            else noPostProcessStmts (HsDoStmt ctxt) stmts }
```

## rearrangeForApplicativeDo

``` haskell
-- | rearrange a list of statements using ApplicativeDoStmt.  See
-- Note [ApplicativeDo].
rearrangeForApplicativeDo
  :: HsDoFlavour
  -> [(ExprLStmt GhcRn, FreeVars)]
  -> RnM ([ExprLStmt GhcRn], FreeVars)

rearrangeForApplicativeDo _ [] = return ([], emptyNameSet)
-- If the do-block contains a single @return@ statement, change it to
-- @pure@ if ApplicativeDo is turned on. See Note [ApplicativeDo].
rearrangeForApplicativeDo ctxt [(one,_)] = do
  (return_name, _) <- lookupQualifiedDoName (HsDoStmt ctxt) returnMName
  (pure_name, _)   <- lookupQualifiedDoName (HsDoStmt ctxt) pureAName
  let monad_names = MonadNames { return_name = return_name
                               , pure_name   = pure_name }
  return $ case needJoin monad_names [one] (Just pure_name) of
    (False, one') -> (one', emptyNameSet)
    (True, _) -> ([one], emptyNameSet)

rearrangeForApplicativeDo ctxt stmts0 = do
  optimal_ado <- goptM Opt_OptimalApplicativeDo
  reorder_ado <- goptM Opt_ReorderCommutativeMonadsAdo
  dflags <- getDynFlags
  let n_clones_reorder = adoReorderNClones dflags

  let mkStmtTree | optimal_ado = mkStmtTreeOptimal
                 | otherwise = mkStmtTreeHeuristic
  
  let dummy_clones = replicate n_clones_reorder stmts
  let stmt_trees = mkStmtTree stmts :| map mkStmtTree dummy_clones
  mapM_ (traceRnTree "rearrangeForADo-Clone resulting tree:") stmt_trees
  let best_tree = minimumBy (comparing stmtTreeCost) stmt_trees

  -- traceRn "rearrangeForADo" (ppr best_tree)
  traceRnTree "rearrangeForADo final tree:" best_tree
  (return_name, _) <- lookupQualifiedDoName (HsDoStmt ctxt) returnMName
  (pure_name, _)   <- lookupQualifiedDoName (HsDoStmt ctxt) pureAName
  let monad_names = MonadNames { return_name = return_name
                               , pure_name   = pure_name }
  stmtTreeToStmts monad_names ctxt best_tree [last] last_fvs
  where
    (stmts,(last,last_fvs)) = findLast stmts0
    findLast [] = error "findLast"
    findLast [last] = ([],last)
    findLast (x:xs) = (x:rest,last) where (rest,last) = findLast xs
    traceRnTree :: String -> ExprStmtTree -> TcRn ()
    traceRnTree label tree =
      traceRn label
        (vcat [ ppr tree
              , text "cost = " <+> ppr (stmtTreeCost tree)
              ])
```

## mkStmtTreeOptimal

``` haskell
-- | Turn a sequence of statements into an ExprStmtTree optimally,
-- using dynamic programming.  /O(n^3)/
mkStmtTreeOptimal :: [(ExprLStmt GhcRn, FreeVars)] -> ExprStmtTree
mkStmtTreeOptimal stmts =
  assert (not (null stmts)) $ -- the empty case is handled by the caller;
                              -- we don't support empty StmtTrees.
  fst (arr ! (0,n))
  where
    n = length stmts - 1
    stmt_arr = listArray (0,n) stmts

    -- lazy cache of optimal trees for subsequences of the input
    arr :: Array (Int,Int) (ExprStmtTree, Cost)
    arr = array ((0,0),(n,n))
             [ ((lo,hi), tree lo hi)
             | lo <- [0..n]
             , hi <- [lo..n] ]

    -- compute the optimal tree for the sequence [lo..hi]
    tree lo hi
      | hi == lo = (StmtTreeOne (stmt_arr ! lo), 1)
      | otherwise =
         case segments [ stmt_arr ! i | i <- [lo..hi] ] of
           [] -> panic "mkStmtTree"
           [_one] -> split lo hi
           segs -> (StmtTreeApplicative trees, Partial.maximum costs)
             where
               bounds = scanl (\(_,hi) a -> (hi+1, hi + length a)) (0,lo-1) segs
               -- We know `costs` must be non-empty, as `length segs >= 2` here.
               (trees,costs) = unzip (map (uncurry split) (tail bounds))

    -- find the best place to split the segment [lo..hi]
    split :: Int -> Int -> (ExprStmtTree, Cost)
    split lo hi
      | hi == lo = (StmtTreeOne (stmt_arr ! lo), 1)
      | otherwise = (StmtTreeBind before after, c1+c2)
        where
         -- As per the paper, for a sequence s1...sn, we want to find
         -- the split with the minimum cost, where the cost is the
         -- sum of the cost of the left and right subsequences.
         --
         -- As an optimisation (also in the paper) if the cost of
         -- s1..s(n-1) is different from the cost of s2..sn, we know
         -- that the optimal solution is the lower of the two.  Only
         -- in the case that these two have the same cost do we need
         -- to do the exhaustive search.
         --
         ((before,c1),(after,c2)) = case nonEmpty [lo .. hi-1] of
             Nothing ->
               ( (StmtTreeOne (stmt_arr ! lo), 1),
                 (StmtTreeOne (stmt_arr ! hi), 1) )
             Just ks
               | left_cost < right_cost
               -> ((left,left_cost), (StmtTreeOne (stmt_arr ! hi), 1))
               | left_cost > right_cost
               -> ((StmtTreeOne (stmt_arr ! lo), 1), (right,right_cost))
               | otherwise -> minimumBy (comparing cost)
                 [ (arr ! (lo,k), arr ! (k+1,hi)) | k <- ks ]
           where
             (left, left_cost) = arr ! (lo,hi-1)
             (right, right_cost) = arr ! (lo+1,hi)
             cost ((_,c1),(_,c2)) = c1 + c2
```

## mkStmtTreeHeuristic

``` haskell
-- | Turn a sequence of statements into an ExprStmtTree using a
-- heuristic algorithm.  /O(n^2)/
mkStmtTreeHeuristic :: [(ExprLStmt GhcRn, FreeVars)] -> ExprStmtTree
mkStmtTreeHeuristic [one] = StmtTreeOne one
mkStmtTreeHeuristic stmts =
  case segments stmts of
    [one] -> split one
    segs -> StmtTreeApplicative (map split segs)
 where
  split [one] = StmtTreeOne one
  split stmts =
    StmtTreeBind (mkStmtTreeHeuristic before) (mkStmtTreeHeuristic after)
    where (before, after) = splitSegment stmts
```

# Estructuras de datos utilizadas y utilidades

## ExprStmtTree

``` haskell
-- | A tree of statements using a mixture of applicative and bind constructs.
data StmtTree a
  = StmtTreeOne a
  | StmtTreeBind (StmtTree a) (StmtTree a)
  | StmtTreeApplicative [StmtTree a]

type ExprStmtTree = StmtTree (ExprLStmt GhcRn, FreeVars)
```

## stmtTreeCost

``` haskell
-- | Calculate the cost of an ExprStmtTree, with a simple heuristic
stmtTreeCost :: ExprStmtTree -> Cost
stmtTreeCost (StmtTreeOne _) = 1
stmtTreeCost (StmtTreeBind l r) = stmtTreeCost l + stmtTreeCost r
stmtTreeCost (StmtTreeApplicative ts) = 
  case ts of
    [] -> 0
    _  -> Partial.maximum (map stmtTreeCost ts)
```

## stmtTreeToStmts

``` haskell
-- | Turn the ExprStmtTree back into a sequence of statements, using
-- ApplicativeStmt where necessary.
stmtTreeToStmts
  :: MonadNames
  -> HsDoFlavour
  -> ExprStmtTree
  -> [ExprLStmt GhcRn]             -- ^ the "tail"
  -> FreeVars                     -- ^ free variables of the tail
  -> RnM ( [ExprLStmt GhcRn]       -- ( output statements,
         , FreeVars )             -- , things we needed

-- If we have a single bind, and we can do it without a join, transform
-- to an ApplicativeStmt.  This corresponds to the rule
--   dsBlock [pat <- rhs] (return expr) = expr <$> rhs
-- In the spec, but we do it here rather than in the desugarer,
-- because we need the typechecker to typecheck the <$> form rather than
-- the bind form, which would give rise to a Monad constraint.
--
-- If we have a single let, and the last statement is @return E@ or @return $ E@,
-- change the @return@ to @pure@.
stmtTreeToStmts monad_names ctxt (StmtTreeOne (L _ (BindStmt xbs pat rhs), _))
                tail _tail_fvs
  | definitelyLazyPattern pat, (False,tail') <- needJoin monad_names tail Nothing
  -- See Note [ApplicativeDo and strict patterns]
  = mkApplicativeStmt ctxt [ApplicativeArgOne
                            { xarg_app_arg_one = xbsrn_failOp xbs
                            , app_arg_pattern  = pat
                            , arg_expr         = rhs
                            , is_body_stmt     = False
                            }]
                      False tail'
stmtTreeToStmts monad_names ctxt (StmtTreeOne (L _ (BodyStmt _ rhs _ _),_))
                tail _tail_fvs
  | (False,tail') <- needJoin monad_names tail Nothing
  = mkApplicativeStmt ctxt
      [ApplicativeArgOne
       { xarg_app_arg_one = Nothing
       , app_arg_pattern  = nlWildPatName
       , arg_expr         = rhs
       , is_body_stmt     = True
       }] False tail'
stmtTreeToStmts monad_names ctxt (StmtTreeOne (let_stmt@(L _ LetStmt{}),_))
                tail _tail_fvs = do
  (pure_name, _) <- lookupQualifiedDoName (HsDoStmt ctxt) pureAName
  return $ case needJoin monad_names tail (Just pure_name) of
    (False, tail') -> (let_stmt : tail', emptyNameSet)
    (True, _) -> (let_stmt : tail, emptyNameSet)

stmtTreeToStmts _monad_names _ctxt (StmtTreeOne (s,_)) tail _tail_fvs =
  return (s : tail, emptyNameSet)

stmtTreeToStmts monad_names ctxt (StmtTreeBind before after) tail tail_fvs = do
  (stmts1, fvs1) <- stmtTreeToStmts monad_names ctxt after tail tail_fvs
  let tail1_fvs = unionNameSets (tail_fvs : map snd (flattenStmtTree after))
  (stmts2, fvs2) <- stmtTreeToStmts monad_names ctxt before stmts1 tail1_fvs
  return (stmts2, fvs1 `plusFV` fvs2)

stmtTreeToStmts monad_names ctxt (StmtTreeApplicative trees) tail tail_fvs = do
   hscEnv <- getTopEnv
   rdrEnv <- getGlobalRdrEnv
   comps <- getCompleteMatchesTcM
   pairs <- mapM (stmtTreeArg ctxt tail_fvs) trees
   strict <- xoptM LangExt.Strict
   let (stmts', fvss) = unzip pairs
   let (need_join, tail') =
     -- See Note [ApplicativeDo and refutable patterns]
         if any (hasRefutablePattern strict hscEnv rdrEnv comps) stmts'
         then (True, tail)
         else needJoin monad_names tail Nothing

   (stmts, fvs) <- mkApplicativeStmt ctxt stmts' need_join tail'
   return (stmts, unionNameSets (fvs:fvss))
 where
   stmtTreeArg _ctxt _tail_fvs (StmtTreeOne (L _ (BindStmt xbs pat exp), _))
     = return (ApplicativeArgOne
               { xarg_app_arg_one = xbsrn_failOp xbs
               , app_arg_pattern  = pat
               , arg_expr         = exp
               , is_body_stmt     = False
               }, emptyFVs)
   stmtTreeArg _ctxt _tail_fvs (StmtTreeOne (L _ (BodyStmt _ exp _ _), _)) =
     return (ApplicativeArgOne
             { xarg_app_arg_one = Nothing
             , app_arg_pattern  = nlWildPatName
             , arg_expr         = exp
             , is_body_stmt     = True
             }, emptyFVs)
   stmtTreeArg ctxt tail_fvs tree = do
     let stmts = flattenStmtTree tree
         pvarset = mkNameSet (concatMap (collectStmtBinders CollNoDictBinders . unLoc . fst) stmts)
                     `intersectNameSet` tail_fvs
         pvars = nameSetElemsStable pvarset
           -- See Note [Deterministic ApplicativeDo and RecursiveDo desugaring]
         pat = mkBigLHsVarPatTup pvars
         tup = mkBigLHsVarTup pvars noExtField
     (stmts',fvs2) <- stmtTreeToStmts monad_names ctxt tree [] pvarset
     (mb_ret, fvs1) <-
        if | Just (L _ (XStmtLR ApplicativeStmt{})) <- lastMaybe stmts' ->
             return (unLoc tup, emptyNameSet)
           | otherwise -> do
             -- Need 'pureAName' and not 'returnMName' here, so that it requires
             -- 'Applicative' and not 'Monad' whenever possible (until #20540 is fixed).
             (pure_name, _) <- lookupQualifiedDoName (HsDoStmt ctxt) pureAName
             let expr = HsApp noExtField (noLocA (genHsVar pure_name)) tup
             return (expr, emptyFVs)
     return ( ApplicativeArgMany
              { xarg_app_arg_many = noExtField
              , app_stmts         = stmts'
              , final_expr        = mb_ret
              , bv_pattern        = pat
              , stmt_context      = ctxt
              }
            , fvs1 `plusFV` fvs2)
```