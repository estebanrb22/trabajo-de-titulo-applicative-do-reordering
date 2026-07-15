{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

returnUsesReboundNameExample03 :: Maybe Int
returnUsesReboundNameExample03 = CD.do
  x <- Just 1
  x <- Just 10
  x <- Just 100
  CD.return x

main :: IO ()
main = print returnUsesReboundNameExample03
