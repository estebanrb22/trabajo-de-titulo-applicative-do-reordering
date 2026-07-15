{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

lazyPatternUnusedExample03 :: Maybe (Int, Int)
lazyPatternUnusedExample03 = CD.do
  ~[x1] <- Just []
  x2 <- Just 10
  x3 <- Just (x2 + 1)
  CD.return (x2, x3)

main :: IO ()
main = print lazyPatternUnusedExample03
