{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)

die :: Dist.T Rational Int
die = Dist.uniform [1 .. 6]

twoDice :: Dist.T Rational Int
twoDice = CD.do
  d1 <- die
  d2 <- die
  CD.return (d1 + d2)

main :: IO ()
main = print (Dist.norm twoDice)