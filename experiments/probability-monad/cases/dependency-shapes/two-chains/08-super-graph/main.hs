{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

twoChainsSuperGraphExample08 :: Dist.T Rational (Int, Int, Int, Int, Int, Int, Int, Int)
twoChainsSuperGraphExample08 = CD.do
  a1 <- Dist.uniform [1, 2]
  b1 <- Dist.uniform [10, 20]
  a2 <- Dist.uniform [a1 + 100, a1 + 200]
  b2 <- Dist.uniform [b1 + 1000, b1 + 2000]
  a3 <- Dist.uniform [a1 + a2 + 10000, a1 + a2 + 20000]
  b3 <- Dist.uniform [b1 + b2 + 100000, b1 + b2 + 200000]
  a4 <- Dist.uniform [a1 + a2 + a3 + 1000000, a1 + a2 + a3 + 2000000]
  b4 <- Dist.uniform [b1 + b2 + b3 + 10000000, b1 + b2 + b3 + 20000000]
  CD.return (a1, a2, a3, a4, b1, b2, b3, b4)

main :: IO ()
main = print (Dist.norm twoChainsSuperGraphExample08)
