{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

readBeforeRebindExample03 :: Maybe (Int, Int)
readBeforeRebindExample03 = CD.do
  x <- Just 1
  y <- Just (x + 10)
  x <- Just 100
  CD.return (y, x)

main :: IO ()
main = print readBeforeRebindExample03
