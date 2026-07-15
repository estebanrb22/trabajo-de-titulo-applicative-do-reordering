{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

chooseIndependentExample03 :: Dist.T Rational (Int, Int, Int)
chooseIndependentExample03 = CD.do
  x1 <- Dist.choose (1 / 4) 1 2
  x2 <- Dist.choose (2 / 3) 10 20
  x3 <- Dist.uniform [100, 200]
  CD.return (x1, x2, x3)

main :: IO ()
main = print (Dist.norm chooseIndependentExample03)
