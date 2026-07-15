{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

superGraphNoReorderExample06 :: Maybe (Int, Int, Int, Int, Int, Int)
superGraphNoReorderExample06 = CD.do
  x1 <- Just 1
  x2 <- Just (x1 + 1)
  x3 <- Just (x1 + x2 + 1)
  x4 <- Just (x1 + x2 + x3 + 1)
  x5 <- Just (x1 + x2 + x3 + x4 + 1)
  x6 <- Just (x1 + x2 + x3 + x4 + x5 + 1)
  CD.return (x1, x2, x3, x4, x5, x6)

main :: IO ()
main = print superGraphNoReorderExample06
