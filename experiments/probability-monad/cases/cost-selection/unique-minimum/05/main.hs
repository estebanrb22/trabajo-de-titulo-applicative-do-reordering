{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

uniqueMinimumExample05 :: Dist.T Rational (Int, Int, Int, Int, Int)
uniqueMinimumExample05 = CD.do
  x1 <- Dist.uniform [1, 2]
  x2 <- Dist.uniform [x1 + 10, x1 + 20]
  x3 <- Dist.uniform [x2 + 100, x2 + 200]
  (x4, _) <- Dist.uniform [(40, 0), (50, 0)]
  x5 <- Dist.uniform [x3 + 1000, x3 + 2000]
  CD.return (x1, x2, x3, x4, x5)

main :: IO ()
main = print (Dist.norm uniqueMinimumExample05)
