{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

weightedIndependentExample03 :: Dist.T Rational (Int, Int, Int)
weightedIndependentExample03 = CD.do
  x1 <- Dist.Cons [(1, 1 / 4), (2, 3 / 4)]
  x2 <- Dist.Cons [(10, 2 / 3), (20, 1 / 3)]
  x3 <- Dist.uniform [100, 200]
  CD.return (x1, x2, x3)

main :: IO ()
main = print (Dist.norm weightedIndependentExample03)
