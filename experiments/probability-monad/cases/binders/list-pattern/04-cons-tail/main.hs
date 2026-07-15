{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)
instance MonadFail (Dist.T Rational) where
  fail _ = Dist.Cons []

listPatternConsTailExample04 :: Dist.T Rational (Int, Int, [Int], Int, Int, Int)
listPatternConsTailExample04 = CD.do
  (x1:x2:xs) <- Dist.uniform [[1, 10, 100], [2, 20, 200, 2000]]
  x3 <- Dist.uniform [x1 + x2, x1 + x2 + 1]
  x4 <- Dist.uniform [sum xs, sum xs + 1]
  x5 <- Dist.uniform [x3 + x4, x3 + x4 + 1]
  CD.return (x1, x2, xs, x3, x4, x5)

main :: IO ()
main = print (Dist.norm listPatternConsTailExample04)
