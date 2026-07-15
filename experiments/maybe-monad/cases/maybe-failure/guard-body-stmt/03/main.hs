{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

guardBodyStmtExample03 :: Maybe (Int, Int)
guardBodyStmtExample03 = CD.do
  x1 <- Just 0
  if x1 > 0 then Just () else Nothing
  x2 <- Just 10
  CD.return (x1, x2)

main :: IO ()
main = print guardBodyStmtExample03
