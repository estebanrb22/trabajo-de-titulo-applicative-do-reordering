{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

noDependenciesExample03 :: Dist.T Rational (Int, Int, Int)
noDependenciesExample03 = CD.do
  x1 <- Dist.uniform [1, 2]
  x2 <- Dist.uniform [10, 20]
  x3 <- Dist.uniform [100, 200]
  CD.return (x1, x2, x3)

main :: IO ()
main = print (Dist.norm noDependenciesExample03)
