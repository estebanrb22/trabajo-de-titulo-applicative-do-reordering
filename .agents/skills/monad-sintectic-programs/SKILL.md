---
name: monad-sintectic-programs
description: Use when creating or modifying synthetic monad Haskell programs in experiments, especially single-example .hs files generated from make cabal-project or make cabal-prob-project.
---

# Monad Synthetic Programs

Use this skill when creating or modifying `.hs` files that contain a single synthetic monad example for the experiments in this repository.

## General Rules

- Each `main.hs` should contain exactly one top-level example value and one `main` that prints that example.
- Keep the example pure in the target monad. Use `main :: IO ()` only as the executable boundary.
- Prefer simple deterministic `Int` expressions unless the case specifically tests failure, patterns, shadowing, probabilistic behavior, or another phenomenon.
- Do not introduce helper functions unless the case specifically needs them.
- The `CD.do` block is the experimental block. Avoid adding extra top-level `do` blocks that may confuse validation scripts.
- The statement count `n` used in names is the number of statements before `CD.return`; the final `CD.return`/`LastStmt` is not counted.

## Default Maybe Template

The default `Maybe` program created by `make cabal-project` has this shape:

```haskell
{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

defaultExample :: Maybe Int
defaultExample = CD.do
  x1 <- Just 5
  x2 <- Just 10
  x3 <- Just (x1 + 15)
  x4 <- Just (x2 + 20)
  CD.return (x3 + x4)

main :: IO ()
main = print defaultExample
```

When adapting this template for a concrete synthetic case, update both the example name and the result type according to the rules below.

## New Case Exploration

Whenever the user asks to address a new specific case, first analyze the case before creating or modifying `.hs` files.

The analysis should cover:

- What abstract precedence graph shape the case is meant to test.
- What statement counts are viable and representative for the case.
- What the minimum graph is: the smallest set of statements and RAW edges that exhibits the phenomenon.
- Whether a supergraph variant is useful: add only extra edges that help test the intended phenomenon, usually transitive or denser versions that do not change the conceptual shape.
- Whether the supergraph would accidentally change the phenomenon; if so, do not call it a supergraph of that case.
- Whether more generic variants are useful, for example by varying the number of independent chains, branch lengths, fanout/fanin arity, or other shape parameters.
- When possible, estimate the expected number of valid topological orders/permutations and the relevant `ApplicativeDo` cost behavior.

Prefer a small representative corpus over many redundant variants. A good case family usually has a minimum example, sometimes a supergraph example, and only the generic variants that demonstrate a genuinely different structural parameter.

For example, a `diamond` case only needs `root`, `join`, and two independent chains between them to show the core phenomenon: one dependency splits into independent branches and later converges. More generic `diamond` variants can then vary the number of chains or vary the length of each chain, but those variants should be added only when they test something useful beyond the minimum two-chain diamond.

## Naming Convention

Name the example value using:

```text
<caseToTest>Example<n>
```

where:

- `<caseToTest>` is written in lower camel case.
- `Example` is literal.
- `<n>` is the zero-padded statement count used by the project variant, for example `03`, `04`, `06`, or `08`.

Examples:

```haskell
minimumNoReorderExample04 :: Maybe (Int, Int, Int, Int)
minimumNoReorderExample04 = CD.do
  ...

main :: IO ()
main = print minimumNoReorderExample04
```

```haskell
twoChainsExample08 :: Maybe (Int, Int, Int, Int, Int, Int, Int, Int)
twoChainsExample08 = CD.do
  ...

main :: IO ()
main = print twoChainsExample08
```

## Return Convention

For synthetic monad examples, return a tuple that consumes all binders defined by the statements in the `CD.do` block.

Use this instead of returning only the last binder or a collapsed aggregate such as a sum.

Good:

```haskell
minimumNoReorderExample04 :: Maybe (Int, Int, Int, Int)
minimumNoReorderExample04 = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 1)
  x3 <- Just (x2 + 1)
  x4 <- Just (x3 + 1)
  CD.return (x1, x2, x3, x4)
```

Avoid for synthetic dependency-shape cases:

```haskell
CD.return x4
```

```haskell
CD.return (x1 + x2 + x3 + x4)
```

The tuple makes all relevant binders observable in `stdout` and forces the generated `ApplicativeDo` code to transport all live values to the tail. The `CD.return` expression does not add precedence edges between the reorderable statements because the final `LastStmt` is separated before constructing the graph.

## Tuple Ordering

The tuple order should make the case easy to inspect.

- For a single chain, use statement order: `(x1, x2, x3, x4)`.
- For two chains, group by chain: `(a1, a2, a3, a4, b1, b2, b3, b4)`.
- For diamond-shaped cases, prefer the conceptual order: `(root, a1, ..., b1, ..., join)`.
- If another ordering better communicates the intended graph shape, use that ordering consistently and keep it simple.

## Probability Template

The default probabilistic program created by `make cabal-prob-project` has this shape:

```haskell
{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

die :: Dist.T Rational Int
die = Dist.uniform [1 .. 6]

twoDice :: Dist.T Rational Int
twoDice = CD.do
  d1 <- die
  d2 <- die
  CD.return (d1 + d2)

main :: IO ()
main = print (Dist.norm twoDice)
```

When adapting this template for a concrete synthetic case, update the example name, result type, statements, and `main`. Remove helper distributions such as `die` unless the case specifically benefits from a named reusable distribution.

## Probability Rules

Use these rules for programs under `experiments/probability-monad`:

- Use `Dist.T Rational` as the target probabilistic monad.
- Keep `instance CD.CommutativeMonad (Dist.T Rational)` in programs that use `CD.do`.
- Print a normalized distribution by default: `main = print (Dist.norm example)`.
- Treat `Dist.norm` in `main` as the canonical output decision for semantic validation. It groups equal outcomes and sums their probabilities before the byte-for-byte output comparison.
- Use `Dist.certainly` for dependency-shape cases where probability is not the phenomenon under test.
- Use small finite supports with `Dist.uniform`, `Dist.choose`, `Dist.relative`, or `Dist.fromFreqs` when the case specifically tests probabilistic behavior.
- Prefer `Rational` probabilities and small supports to keep outputs deterministic and avoid support-size explosion across permutations.
- Ensure the returned value has `Ord` and `Show`, because `Dist.norm` and `print` require them.
- Avoid printing `Dist.decons` for validation cases, because it exposes representation order and duplicate outcomes instead of the canonical distribution.
- Avoid random sampling, simulation, or IO inside the probabilistic example; the only IO should be `main`.

For probabilistic examples, use the Cabal validation backend because the programs depend on the external `probability` package:

```text
make test-cabal experiments/probability-monad/<case-dir>
```

Do not use the direct GHC validation wrapper for these cases unless the program has no external package dependency.

## Probability Failure And Conditioning

`Dist.T Rational` should not be treated as a drop-in replacement for `Maybe` failure cases.

- Do not use strict refutable patterns, such as list patterns, unless the case explicitly defines and tests a valid failure semantics.
- Do not copy `Nothing` or `MonadFail Maybe` cases directly.
- Model probabilistic observation or impossible events explicitly with distribution operations.
- Use `Dist.filter` or `>>=?` only when the event keeps at least one outcome; filtering every outcome calls `fromFreqs []` and is not a good default validation case.
- Use `Dist.Cons []` only for cases that deliberately test an impossible distribution and document that intent in the case name.
- Body statements can model observations, for example `Dist.filter predicate distribution`, but they should remain finite and deterministic.

## Probability Case Families

The probability corpus documented in `experiments/probability-monad/cases.md` is not a byte-for-byte copy of the `Maybe` corpus.

- Reusable graph families: `dependency-shapes`, `let-statements`, `body-stmts`, `shadowing`, `cost-selection`, and `controls`.
- Reusable binder families: tuple, nested, wildcard, as-pattern, and lazy-pattern cases.
- Adapted families: list-pattern and `maybe-failure` cases, because strict refutable patterns and `Nothing` are specific to `Maybe`.
- Probability-specific families: weighted distributions, duplicate outcome normalization, dependent support, conditioning, and impossible distributions.
