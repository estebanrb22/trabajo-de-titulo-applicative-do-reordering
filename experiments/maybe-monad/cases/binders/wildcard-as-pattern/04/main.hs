{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

wildcardAsPatternExample04 :: Maybe ((Int, Int), Int, Int, Int, Int)
wildcardAsPatternExample04 = CD.do
  pair@(x1, _) <- Just (1, 10)
  x2 <- Just (fst pair + 20)
  x3 <- Just (x1 + 30)
  x4 <- Just (x2 + x3)
  CD.return (pair, x1, x2, x3, x4)

main :: IO ()
main = print wildcardAsPatternExample04
