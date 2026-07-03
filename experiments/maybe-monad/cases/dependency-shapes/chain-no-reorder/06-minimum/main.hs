{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

minimumNoReorderExample06 :: Maybe Int
minimumNoReorderExample06 = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 1)
  x3 <- Just (x2 + 1)
  x4 <- Just (x3 + 1)
  x5 <- Just (x4 + 1)
  x6 <- Just (x5 + 1)
  CD.return x6

main :: IO ()
main = print minimumNoReorderExample06
