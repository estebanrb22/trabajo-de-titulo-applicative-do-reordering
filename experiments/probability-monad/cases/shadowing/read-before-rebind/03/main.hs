{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

readBeforeRebindExample03 :: Dist.T Rational (Int, Int)
readBeforeRebindExample03 = CD.do
  x <- Dist.uniform [1, 2]
  y <- Dist.uniform [x + 10, x + 20]
  x <- Dist.uniform [100, 200]
  CD.return (y, x)

main :: IO ()
main = print (Dist.norm readBeforeRebindExample03)
