{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

readAfterRebindExample03 :: Dist.T Rational (Int, Int)
readAfterRebindExample03 = CD.do
  x <- Dist.uniform [1, 2]
  x <- Dist.uniform [10, 20]
  y <- Dist.uniform [x + 100, x + 200]
  CD.return (x, y)

main :: IO ()
main = print (Dist.norm readAfterRebindExample03)
