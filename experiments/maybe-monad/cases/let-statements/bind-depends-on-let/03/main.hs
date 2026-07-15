{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

bindDependsOnLetExample03 :: Maybe (Int, Int, Int)
bindDependsOnLetExample03 = CD.do
  let x1 = 10
  x2 <- Just (x1 + 1)
  x3 <- Just 100
  CD.return (x1, x2, x3)

main :: IO ()
main = print bindDependsOnLetExample03
