{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

listPatternTwoElementsExample03 :: Maybe (Int, Int, Int, Int)
listPatternTwoElementsExample03 = CD.do
  [x1, x2] <- Just [1, 10]
  x3 <- Just (x1 + 1)
  x4 <- Just (x2 + 1)
  CD.return (x1, x2, x3, x4)

main :: IO ()
main = print listPatternTwoElementsExample03
