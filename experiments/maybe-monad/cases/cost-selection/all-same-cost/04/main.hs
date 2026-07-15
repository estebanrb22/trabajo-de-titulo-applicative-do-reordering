{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

allSameCostExample04 :: Maybe (Int, Int, Int, Int)
allSameCostExample04 = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 10)
  x3 <- Just (x1 + 20)
  x4 <- Just (x1 + 30)
  CD.return (x1, x2, x3, x4)

main :: IO ()
main = print allSameCostExample04
