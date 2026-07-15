{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

letShadowingExample04 :: Dist.T Rational (Int, Int, Int)
letShadowingExample04 = CD.do
  x <- Dist.uniform [1, 2]
  oldX <- Dist.certainly x
  let x = 100
  y <- Dist.uniform [x + oldX, x + oldX + 1]
  CD.return (oldX, x, y)

main :: IO ()
main = print (Dist.norm letShadowingExample04)
