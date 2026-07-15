{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

dependentSupportExample03 :: Dist.T Rational (Int, Int, Int)
dependentSupportExample03 = CD.do
  x1 <- Dist.uniform [1, 2]
  x2 <- if x1 == 1
        then Dist.certainly 10
        else Dist.uniform [20, 30]
  x3 <- Dist.uniform [100, 200]
  CD.return (x1, x2, x3)

main :: IO ()
main = print (Dist.norm dependentSupportExample03)
