{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

noDependenciesExample04 :: Dist.T Rational (Int, Int, Int, Int)
noDependenciesExample04 = CD.do
  x1 <- Dist.uniform [1, 2]
  x2 <- Dist.uniform [10, 20]
  x3 <- Dist.uniform [100, 200]
  x4 <- Dist.uniform [1000, 2000]
  CD.return (x1, x2, x3, x4)

main :: IO ()
main = print (Dist.norm noDependenciesExample04)
