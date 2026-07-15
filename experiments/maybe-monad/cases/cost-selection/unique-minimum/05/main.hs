{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

uniqueMinimumExample05 :: Maybe (Int, Int, Int, Int, Int)
uniqueMinimumExample05 = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 10)
  x3 <- Just (x2 + 20)
  (x4, _) <- Just (40, 0)
  x5 <- Just (x3 + 30)
  CD.return (x1, x2, x3, x4, x5)

main :: IO ()
main = print uniqueMinimumExample05
