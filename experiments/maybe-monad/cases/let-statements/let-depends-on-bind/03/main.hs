{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

letDependsOnBindExample03 :: Maybe (Int, Int, Int)
letDependsOnBindExample03 = CD.do
  x1 <- Just 10
  let x2 = x1 + 1
  x3 <- Just 100
  CD.return (x1, x2, x3)

main :: IO ()
main = print letDependsOnBindExample03
