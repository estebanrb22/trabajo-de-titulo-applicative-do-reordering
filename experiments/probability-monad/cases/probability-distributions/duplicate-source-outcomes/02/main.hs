{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

duplicateSourceOutcomesExample02 :: Dist.T Rational (Int, Int)
duplicateSourceOutcomesExample02 = CD.do
  x1 <- Dist.Cons [(1, 1 / 4), (1, 1 / 4), (2, 1 / 2)]
  x2 <- Dist.uniform [10, 20]
  CD.return (x1, x2)

main :: IO ()
main = print (Dist.norm duplicateSourceOutcomesExample02)
