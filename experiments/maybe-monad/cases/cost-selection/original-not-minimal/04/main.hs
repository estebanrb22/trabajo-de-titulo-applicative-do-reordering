{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

originalNotMinimalExample04 :: Maybe (Int, Int, Int, Int)
originalNotMinimalExample04 = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 10)
  x3 <- Just 100
  x4 <- Just (x1 + x3)
  CD.return (x1, x2, x3, x4)

main :: IO ()
main = print originalNotMinimalExample04
