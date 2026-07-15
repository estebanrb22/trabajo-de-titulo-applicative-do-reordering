{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

tuplePatternWildcardExample03 :: Maybe (Int, Int, Int, Int)
tuplePatternWildcardExample03 = CD.do
  (_, x1, x2) <- Just (0, 10, 100)
  x3 <- Just (x1 + 1)
  x4 <- Just (x2 + 1)
  CD.return (x1, x2, x3, x4)

main :: IO ()
main = print tuplePatternWildcardExample03
