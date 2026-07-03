{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv n d = Just (n `div` d)

mixedDependencyExample :: Maybe Int
mixedDependencyExample = CD.do
  x1a <- Just 10
  x1  <- Just x1a
  x2  <- Just 5
  x3  <- safeDiv x1 2
  x4a <- Just (x2 + 15)
  x4  <- Just x4a
  CD.return (x3 + x4)

main :: IO ()
main = print mixedDependencyExample