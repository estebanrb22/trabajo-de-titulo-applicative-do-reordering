{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

diamondShapeExample04 :: Dist.T Rational (Int, Int, Int, Int)
diamondShapeExample04 = CD.do
  root <- Dist.uniform [1, 2]
  a1 <- Dist.uniform [root + 10, root + 20]
  b1 <- Dist.uniform [root + 100, root + 200]
  join <- Dist.uniform [a1 + b1 + 1000, a1 + b1 + 2000]
  CD.return (root, a1, b1, join)

main :: IO ()
main = print (Dist.norm diamondShapeExample04)
