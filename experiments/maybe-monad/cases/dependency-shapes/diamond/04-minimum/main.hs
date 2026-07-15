{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

diamondShapeExample04 :: Maybe (Int, Int, Int, Int)
diamondShapeExample04 = CD.do
  root <- Just 1
  a1 <- Just (root + 10)
  b1 <- Just (root + 20)
  join <- Just (a1 + b1)
  CD.return (root, a1, b1, join)

main :: IO ()
main = print diamondShapeExample04
