{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

minimumNoReorderExample04 :: Maybe Int
minimumNoReorderExample04 = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 1)
  x3 <- Just (x2 + 1)
  x4 <- Just (x3 + 1)
  CD.return x4

main :: IO ()
main = print minimumNoReorderExample04
