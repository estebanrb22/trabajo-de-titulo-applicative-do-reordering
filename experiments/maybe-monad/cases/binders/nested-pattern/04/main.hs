{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

nestedPatternExample04 :: Maybe (Int, Int, Int, Int, Int, Int, Int)
nestedPatternExample04 = CD.do
  ((x1, x2), (x3, x4)) <- Just ((1, 10), (100, 1000))
  x5 <- Just (x1 + x3)
  x6 <- Just (x2 + x4)
  x7 <- Just (x5 + x6)
  CD.return (x1, x2, x3, x4, x5, x6, x7)

main :: IO ()
main = print nestedPatternExample04
