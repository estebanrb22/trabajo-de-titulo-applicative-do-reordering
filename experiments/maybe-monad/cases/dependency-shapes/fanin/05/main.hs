{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

fanInExample05 :: Maybe (Int, Int, Int, Int, Int)
fanInExample05 = CD.do
  x1 <- Just 1
  x2 <- Just 10
  x3 <- Just 100
  x4 <- Just 1000
  x5 <- Just (x1 + x2 + x3 + x4)
  CD.return (x1, x2, x3, x4, x5)

main :: IO ()
main = print fanInExample05
