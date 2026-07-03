{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

smallExample :: Maybe Int
smallExample  = CD.do
  x1 <- Just 5
  x2 <- Just 10
  CD.return (x1 + x2)

main :: IO ()
main = print smallExample
