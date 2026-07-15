{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

impossibleIndependentExample03 :: Dist.T Rational (Int, Int)
impossibleIndependentExample03 = CD.do
  x1 <- Dist.uniform [1, 2]
  (Dist.Cons [] :: Dist.T Rational ())
  x2 <- Dist.uniform [10, 20]
  CD.return (x1, x2)

main :: IO ()
main = print (Dist.norm impossibleIndependentExample03)
