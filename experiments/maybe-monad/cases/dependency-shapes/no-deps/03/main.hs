{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

noDependenciesExample03 :: Maybe (Int, Int, Int)
noDependenciesExample03 = CD.do
  x1 <- Just 1
  x2 <- Just 2
  x3 <- Just 3
  CD.return (x1, x2, x3)

main :: IO ()
main = print noDependenciesExample03
