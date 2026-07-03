{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

program :: Maybe Int
program = CD.do
  x <- Just 1
  y <- Just x
  x <- Just 2
  CD.return (y + x)

main :: IO ()
main = print program