{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

bindDependsOnLetExample03 :: Dist.T Rational (Int, Int, Int)
bindDependsOnLetExample03 = CD.do
  let x1 = 10
  x2 <- Dist.uniform [x1 + 1, x1 + 2]
  x3 <- Dist.uniform [100, 200]
  CD.return (x1, x2, x3)

main :: IO ()
main = print (Dist.norm bindDependsOnLetExample03)
