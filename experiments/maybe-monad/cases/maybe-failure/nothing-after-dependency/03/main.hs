{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

nothingAfterDependencyExample03 :: Maybe (Int, Int, Int)
nothingAfterDependencyExample03 = CD.do
  x1 <- Just 0
  x2 <- if x1 > 0 then Just 1 else Nothing
  x3 <- Just 100
  CD.return (x1, x2, x3)

main :: IO ()
main = print nothingAfterDependencyExample03
