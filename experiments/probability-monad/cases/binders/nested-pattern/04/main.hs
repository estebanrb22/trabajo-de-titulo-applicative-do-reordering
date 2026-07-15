{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

nestedPatternExample04 :: Dist.T Rational (Int, Int, Int, Int, Int, Int, Int)
nestedPatternExample04 = CD.do
  ((x1, x2), (x3, x4)) <- Dist.uniform [((1, 10), (100, 1000)), ((2, 20), (200, 2000))]
  x5 <- Dist.uniform [x1 + x3, x1 + x3 + 1]
  x6 <- Dist.uniform [x2 + x4, x2 + x4 + 1]
  x7 <- Dist.uniform [x5 + x6, x5 + x6 + 1]
  CD.return (x1, x2, x3, x4, x5, x6, x7)

main :: IO ()
main = print (Dist.norm nestedPatternExample04)
