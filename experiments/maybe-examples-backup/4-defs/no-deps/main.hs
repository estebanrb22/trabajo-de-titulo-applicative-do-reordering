{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv n d = Just (n `div` d)

noDependencyExample :: Maybe Int
noDependencyExample = CD.do
  x1 <- Just 5
  x2 <- Just 10
  x3 <- Just 15
  x4 <- Just 20
  CD.return (x1 + x2 + x3 + x4)

main :: IO ()
main = print noDependencyExample
