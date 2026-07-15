{-# LANGUAGE ApplicativeDo #-}

module Main (main) where

import qualified Numeric.Probability.Distribution as Dist

plainDoNoMarkerExample04 :: Dist.T Rational (Int, Int, Int, Int)
plainDoNoMarkerExample04 = do
  a1 <- Dist.uniform [1, 2]
  b1 <- Dist.uniform [10, 20]
  a2 <- Dist.uniform [a1 + 100, a1 + 200]
  b2 <- Dist.uniform [b1 + 1000, b1 + 2000]
  return (a1, a2, b1, b2)

main :: IO ()
main = print (Dist.norm plainDoNoMarkerExample04)
