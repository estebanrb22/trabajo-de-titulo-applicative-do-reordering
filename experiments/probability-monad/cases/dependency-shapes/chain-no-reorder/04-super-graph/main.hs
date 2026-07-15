{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

superGraphNoReorderExample04 :: Dist.T Rational (Int, Int, Int, Int)
superGraphNoReorderExample04 = CD.do
  x1 <- Dist.uniform [1, 2]
  x2 <- Dist.uniform [x1 + 10, x1 + 20]
  x3 <- Dist.uniform [x1 + x2 + 100, x1 + x2 + 200]
  x4 <- Dist.uniform [x1 + x2 + x3 + 1000, x1 + x2 + x3 + 2000]
  CD.return (x1, x2, x3, x4)

main :: IO ()
main = print (Dist.norm superGraphNoReorderExample04)
