{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

tuplePatternTernaryExample05 :: Maybe (Int, Int, Int, Int, Int, Int, Int)
tuplePatternTernaryExample05 = CD.do
  (x1, x2, x3) <- Just (1, 10, 100)
  x4 <- Just (x1 + 1)
  x5 <- Just (x2 + 1)
  x6 <- Just (x3 + 1)
  x7 <- Just (x4 + x5 + x6)
  CD.return (x1, x2, x3, x4, x5, x6, x7)

main :: IO ()
main = print tuplePatternTernaryExample05
