{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

qualifiedDoMarkerExample04 :: Dist.T Rational (Int, Int, Int, Int)
qualifiedDoMarkerExample04 = CD.do
  a1 <- Dist.uniform [1, 2]
  b1 <- Dist.uniform [10, 20]
  a2 <- Dist.uniform [a1 + 100, a1 + 200]
  b2 <- Dist.uniform [b1 + 1000, b1 + 2000]
  CD.return (a1, a2, b1, b2)

main :: IO ()
main = print (Dist.norm qualifiedDoMarkerExample04)
