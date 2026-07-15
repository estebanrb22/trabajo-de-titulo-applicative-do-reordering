{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

rebindSameNameExample03 :: Maybe (Int, Int)
rebindSameNameExample03 = CD.do
  x <- Just 1
  x <- Just 10
  y <- Just 100
  CD.return (x, y)

main :: IO ()
main = print rebindSameNameExample03
