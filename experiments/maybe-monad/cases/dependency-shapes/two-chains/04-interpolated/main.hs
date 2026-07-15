{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

twoChainsExample04 :: Maybe (Int, Int, Int, Int)
twoChainsExample04 = CD.do
  a1 <- Just 1
  b1 <- Just 10
  a2 <- Just (a1 + 1)
  b2 <- Just (b1 + 1)
  CD.return (a1, a2, b1, b2)

main :: IO ()
main = print twoChainsExample04
