module Main (main) where

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv n d = Just (n `div` d)

mixedDependencyExample :: Maybe Int
mixedDependencyExample = do
  x2 <- Just 5
  x4 <- Just (x2 + 15)
  x1 <- Just 10
  x3 <- safeDiv x1 2
  return (x3 + x4)

main :: IO ()
main = print mixedDependencyExample
