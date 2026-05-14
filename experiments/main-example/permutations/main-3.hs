module Main (main) where

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv n d = Just (n `div` d)

mixedDependencyExample :: Maybe Int
mixedDependencyExample = do
  x1a <- Just 10
  x1  <- Just x1a
  x3  <- safeDiv x1 2
  x2  <- Just 5
  x4a <- Just (x2 + 15)
  x4  <- Just x4a
  return (x3 + x4)

main :: IO ()
main = print mixedDependencyExample
