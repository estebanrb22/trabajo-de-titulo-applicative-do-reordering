{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

diamondShapeExample06 :: Dist.T Rational (Int, Int, Int, Int, Int, Int)
diamondShapeExample06 = CD.do
  root <- Dist.uniform [1, 2]
  a1 <- Dist.uniform [root + 10, root + 20]
  b1 <- Dist.uniform [root + 100, root + 200]
  a2 <- Dist.uniform [a1 + 1000, a1 + 2000]
  b2 <- Dist.uniform [b1 + 10000, b1 + 20000]
  join <- Dist.uniform [a2 + b2 + 100000, a2 + b2 + 200000]
  CD.return (root, a1, a2, b1, b2, join)

main :: IO ()
main = print (Dist.norm diamondShapeExample06)
