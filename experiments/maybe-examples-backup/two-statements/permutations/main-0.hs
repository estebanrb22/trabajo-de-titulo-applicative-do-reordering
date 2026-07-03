module Main (main) where

smallExample :: Maybe Int
smallExample  = do
  x1 <- Just 5
  x2 <- Just 10
  return (x1 + x2)

main :: IO ()
main = print smallExample
