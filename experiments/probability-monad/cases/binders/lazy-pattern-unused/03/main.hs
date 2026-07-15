{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

lazyPatternUnusedExample03 :: Dist.T Rational (Int, Int)
lazyPatternUnusedExample03 = CD.do
  ~[x1] <- Dist.certainly []
  x2 <- Dist.uniform [10, 20]
  x3 <- Dist.uniform [x2 + 1, x2 + 2]
  CD.return (x2, x3)

main :: IO ()
main = print (Dist.norm lazyPatternUnusedExample03)
