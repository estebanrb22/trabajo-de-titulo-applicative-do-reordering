{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

listPatternConsTailExample04 :: Maybe (Int, Int, [Int], Int, Int, Int)
listPatternConsTailExample04 = CD.do
  (x1:x2:xs) <- Just [1, 10, 100, 1000]
  x3 <- Just (x1 + x2)
  x4 <- Just (sum xs)
  x5 <- Just (x3 + x4)
  CD.return (x1, x2, xs, x3, x4, x5)

main :: IO ()
main = print listPatternConsTailExample04
