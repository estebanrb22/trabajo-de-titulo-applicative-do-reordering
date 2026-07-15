{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

tuplePatternTernaryExample05 :: Dist.T Rational (Int, Int, Int, Int, Int, Int, Int)
tuplePatternTernaryExample05 = CD.do
  (x1, x2, x3) <- Dist.uniform [(1, 10, 100), (2, 20, 200)]
  x4 <- Dist.uniform [x1 + 1, x1 + 2]
  x5 <- Dist.uniform [x2 + 1, x2 + 2]
  x6 <- Dist.uniform [x3 + 1, x3 + 2]
  x7 <- Dist.uniform [x4 + x5 + x6, x4 + x5 + x6 + 1]
  CD.return (x1, x2, x3, x4, x5, x6, x7)

main :: IO ()
main = print (Dist.norm tuplePatternTernaryExample05)
