{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

manyMinimumsExample06 :: Maybe (Int, Int, Int, Int, Int, Int)
manyMinimumsExample06 = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 10)
  x3 <- Just 100
  x4 <- Just (x3 + 20)
  x5 <- Just (x4 + 30)
  x6 <- Just (x2 + 40)
  CD.return (x1, x2, x3, x4, x5, x6)

main :: IO ()
main = print manyMinimumsExample06
