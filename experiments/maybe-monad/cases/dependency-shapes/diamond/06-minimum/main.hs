{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

diamondShapeExample06 :: Maybe (Int, Int, Int, Int, Int, Int)
diamondShapeExample06 = CD.do
  root <- Just 1
  a1 <- Just (root + 10)
  b1 <- Just (root + 20)
  a2 <- Just (a1 + 1)
  b2 <- Just (b1 + 1)
  join <- Just (a2 + b2)
  CD.return (root, a1, a2, b1, b2, join)

main :: IO ()
main = print diamondShapeExample06
