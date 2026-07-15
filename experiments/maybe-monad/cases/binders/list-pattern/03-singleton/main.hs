{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

listPatternSingletonExample03 :: Maybe (Int, Int, Int)
listPatternSingletonExample03 = CD.do
  [x1] <- Just [10]
  x2 <- Just 20
  x3 <- Just (x1 + x2)
  CD.return (x1, x2, x3)

main :: IO ()
main = print listPatternSingletonExample03
