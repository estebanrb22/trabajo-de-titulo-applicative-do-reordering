{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

wildcardAsPatternExample04 :: Dist.T Rational ((Int, Int), Int, Int, Int, Int)
wildcardAsPatternExample04 = CD.do
  pair@(x1, _) <- Dist.uniform [(1, 10), (2, 20)]
  x2 <- Dist.uniform [fst pair + 20, fst pair + 30]
  x3 <- Dist.uniform [x1 + 30, x1 + 40]
  x4 <- Dist.uniform [x2 + x3, x2 + x3 + 1]
  CD.return (pair, x1, x2, x3, x4)

main :: IO ()
main = print (Dist.norm wildcardAsPatternExample04)
