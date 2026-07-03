{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

superGraphNoReorderExample04 :: Maybe Int
superGraphNoReorderExample04 = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 1)
  x3 <- Just (x1 + x2 + 1)
  x4 <- Just (x1 + x2 + x3 + 1)
  CD.return x4

main :: IO ()
main = print superGraphNoReorderExample04
