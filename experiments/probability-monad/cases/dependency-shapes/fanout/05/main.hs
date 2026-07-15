{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

fanOutExample05 :: Dist.T Rational (Int, Int, Int, Int, Int)
fanOutExample05 = CD.do
  x1 <- Dist.uniform [1, 2]
  x2 <- Dist.uniform [x1 + 10, x1 + 20]
  x3 <- Dist.uniform [x1 + 100, x1 + 200]
  x4 <- Dist.uniform [x1 + 1000, x1 + 2000]
  x5 <- Dist.uniform [x1 + 10000, x1 + 20000]
  CD.return (x1, x2, x3, x4, x5)

main :: IO ()
main = print (Dist.norm fanOutExample05)
