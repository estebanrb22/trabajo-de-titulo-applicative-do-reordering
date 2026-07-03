{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad IO

program :: IO Int
program = CD.do
  x <- putStrLn "A" >> pure 1
  y <- putStrLn "B" >> pure 2
  CD.return (x + y)

main :: IO ()
main = program >>= print