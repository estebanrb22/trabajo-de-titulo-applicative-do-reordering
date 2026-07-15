{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)
instance MonadFail (Dist.T Rational) where
  fail _ = Dist.Cons []

listPatternTwoElementsExample03 :: Dist.T Rational (Int, Int, Int, Int)
listPatternTwoElementsExample03 = CD.do
  [x1, x2] <- Dist.uniform [[1, 10], [2, 20]]
  x3 <- Dist.uniform [x1 + 1, x1 + 2]
  x4 <- Dist.uniform [x2 + 1, x2 + 2]
  CD.return (x1, x2, x3, x4)

main :: IO ()
main = print (Dist.norm listPatternTwoElementsExample03)
