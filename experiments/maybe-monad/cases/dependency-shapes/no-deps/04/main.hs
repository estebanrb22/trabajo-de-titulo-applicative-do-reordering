{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

noDependencies04 :: Maybe Int
noDependencies04 = CD.do
  x1 <- Just 1
  x2 <- Just 2
  x3 <- Just 3
  x4 <- Just 4
  CD.return (x1 + x2 + x3 + x4)

main :: IO ()
main = print noDependencies04