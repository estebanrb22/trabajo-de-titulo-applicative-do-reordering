{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

twoChainsExample08 :: Maybe (Int, Int, Int, Int, Int, Int, Int, Int)
twoChainsExample08 = CD.do
  a1 <- Just 1
  b1 <- Just 10
  a2 <- Just (a1 + 1)
  b2 <- Just (b1 + 1)
  a3 <- Just (a2 + 1)
  b3 <- Just (b2 + 1)
  a4 <- Just (a3 + 1)
  b4 <- Just (b3 + 1)
  CD.return (a1, a2, a3, a4, b1, b2, b3, b4)

main :: IO ()
main = print twoChainsExample08
