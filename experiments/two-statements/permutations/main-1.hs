module Main (main) where

smallExample :: Maybe Int
smallExample  = do
  x2 <- Just 10
  x1 <- Just 5
  return (x1 + x2)

main :: IO ()
main = print smallExample
