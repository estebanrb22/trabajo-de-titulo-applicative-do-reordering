{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

nothingIndependentExample03 :: Maybe (Int, Int, Int)
nothingIndependentExample03 = CD.do
  x1 <- Just 1
  x2 <- Nothing
  x3 <- Just 10
  CD.return (x1, x2, x3)

main :: IO ()
main = print nothingIndependentExample03
