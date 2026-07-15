{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

listPatternWildcardExample03 :: Maybe (Int, Int, Int, Int)
listPatternWildcardExample03 = CD.do
  [x1, _, x2] <- Just [1, 999, 10]
  x3 <- Just (x1 + 1)
  x4 <- Just (x2 + 1)
  CD.return (x1, x2, x3, x4)

main :: IO ()
main = print listPatternWildcardExample03
