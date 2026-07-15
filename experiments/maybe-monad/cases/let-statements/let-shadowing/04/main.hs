{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

letShadowingExample04 :: Maybe (Int, Int, Int)
letShadowingExample04 = CD.do
  x <- Just 1
  oldX <- Just x
  let x = 100
  y <- Just (x + oldX)
  CD.return (oldX, x, y)

main :: IO ()
main = print letShadowingExample04
