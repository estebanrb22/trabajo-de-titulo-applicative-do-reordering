{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

patternFailTupleExample03 :: Maybe (Int, Int, Int, Int)
patternFailTupleExample03 = CD.do
  (x1, Just x2) <- Just (1, Nothing)
  x3 <- Just (x1 + x2)
  x4 <- Just 100
  CD.return (x1, x2, x3, x4)

main :: IO ()
main = print patternFailTupleExample03
