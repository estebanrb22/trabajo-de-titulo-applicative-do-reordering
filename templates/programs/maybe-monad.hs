{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

defaultExample :: Maybe Int
defaultExample = CD.do
  x1 <- Just 5
  x2 <- Just 10
  x3 <- Just (x1 + 15)
  x4 <- Just (x2 + 20)
  CD.return (x3 + x4)

main :: IO ()
main = print defaultExample