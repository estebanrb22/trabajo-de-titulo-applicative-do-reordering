{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

bodyStmtDependentExample03 :: Dist.T Rational (Int, Int)
bodyStmtDependentExample03 = CD.do
  x1 <- Dist.uniform [1, 2]
  Dist.certainly (x1 + 10)
  x2 <- Dist.uniform [100, 200]
  CD.return (x1, x2)

main :: IO ()
main = print (Dist.norm bodyStmtDependentExample03)
