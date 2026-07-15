{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

chooseDependentExample03 :: Dist.T Rational (Int, Int, Int)
chooseDependentExample03 = CD.do
  x1 <- Dist.uniform [1, 2]
  x2 <- if x1 == 1
        then Dist.choose (1 / 4) 10 20
        else Dist.choose (3 / 4) 10 20
  x3 <- Dist.uniform [100, 200]
  CD.return (x1, x2, x3)

main :: IO ()
main = print (Dist.norm chooseDependentExample03)
