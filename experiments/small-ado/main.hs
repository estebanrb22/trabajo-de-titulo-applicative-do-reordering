{-# LANGUAGE ApplicativeDo #-}

module Main (main) where

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv n d = Just (n `div` d)

mixedDependencyExample :: Maybe Int
mixedDependencyExample = do
  x <- Just 84
  y <- safeDiv x 2
  z <- Just 5
  pure (x + y + z)

main :: IO ()
main = print mixedDependencyExample
