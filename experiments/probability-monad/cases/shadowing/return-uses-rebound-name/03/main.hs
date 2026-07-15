{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

returnUsesReboundNameExample03 :: Dist.T Rational Int
returnUsesReboundNameExample03 = CD.do
  x <- Dist.uniform [1, 2]
  x <- Dist.uniform [10, 20]
  x <- Dist.uniform [100, 200]
  CD.return x

main :: IO ()
main = print (Dist.norm returnUsesReboundNameExample03)
