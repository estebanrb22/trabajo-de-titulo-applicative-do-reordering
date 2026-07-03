{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

independentExample :: Maybe Int
independentExample = CD.do
  x1 <- Just 10
  x2 <- Just 5
  CD.return (x1 + x2)

main :: IO ()
main = print independentExample
