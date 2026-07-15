{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

bodyStmtIndependentExample03 :: Maybe (Int, Int)
bodyStmtIndependentExample03 = CD.do
  x1 <- Just 1
  Just ()
  x2 <- Just 10
  CD.return (x1, x2)

main :: IO ()
main = print bodyStmtIndependentExample03
