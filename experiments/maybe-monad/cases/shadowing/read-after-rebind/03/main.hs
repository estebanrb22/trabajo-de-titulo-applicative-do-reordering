{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

readAfterRebindExample03 :: Maybe (Int, Int)
readAfterRebindExample03 = CD.do
  x <- Just 1
  x <- Just 10
  y <- Just (x + 100)
  CD.return (x, y)

main :: IO ()
main = print readAfterRebindExample03
