{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

bodyStmtDependentExample03 :: Maybe (Int, Int)
bodyStmtDependentExample03 = CD.do
  x1 <- Just 1
  Just (x1 + 10)
  x2 <- Just 100
  CD.return (x1, x2)

main :: IO ()
main = print bodyStmtDependentExample03
