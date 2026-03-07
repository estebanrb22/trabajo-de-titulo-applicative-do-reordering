{-# LANGUAGE ApplicativeDo #-}

module Main (main) where

import Text.Printf (printf)

data Report = Report
  { pureApplicativePlan :: Int
  , mixedDependencyPlan :: Int
  , bodyStmtPlan :: Int
  , strictPatternPlan :: Int
  , nestedPlan :: Int
  , refutablePatternPlan :: Int
  , joinPlan :: Int
  , grandTotal :: Int
  }
  deriving (Show)

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv n d = Just (n `div` d)

ensure :: Bool -> Maybe ()
ensure True = Just ()
ensure False = Nothing

pureApplicativeExample :: Maybe Int
pureApplicativeExample = do
  a <- Just 10
  b <- Just 20
  c <- Just 3
  pure (a + b * c)

mixedDependencyExample :: Maybe Int
mixedDependencyExample = do
  x <- Just 84
  y <- safeDiv x 2
  z <- Just 5
  pure (x + y + z)

bodyStmtExample :: Maybe Int
bodyStmtExample = do
  x <- Just 7
  ensure (x > 0)
  y <- Just 11
  pure (x * y)

strictPatternExample :: Maybe Int
strictPatternExample = do
  (x, y) <- Just (6, 7)
  z <- Just 3
  pure (x + y + z)

nestedExample :: Maybe Int
nestedExample = do
  seed <- Just 9
  (left, right) <- do
    a <- Just (seed - 1)
    b <- Just (seed + 1)
    pure (a, b)
  extra <- Just 4
  pure (left + right + extra)

refutablePatternExample :: Maybe Int
refutablePatternExample = do
  Just payload <- Just (Just 21)
  factor <- Just 2
  pure (payload * factor)

joinExample :: Maybe Int
joinExample = do
  x <- Just 8
  y <- Just 9
  wrap (x + y)
  where
    wrap n = Just n

combinedReport :: Maybe Report
combinedReport = do
  purePlan <- pureApplicativeExample
  mixedPlan <- mixedDependencyExample
  bodyPlan <- bodyStmtExample
  strictPlan <- strictPatternExample
  nestedPlanValue <- nestedExample
  refutablePlan <- refutablePatternExample
  joinPlanValue <- joinExample
  let total =
        purePlan
          + mixedPlan
          + bodyPlan
          + strictPlan
          + nestedPlanValue
          + refutablePlan
          + joinPlanValue
  pure
    Report
      { pureApplicativePlan = purePlan
      , mixedDependencyPlan = mixedPlan
      , bodyStmtPlan = bodyPlan
      , strictPatternPlan = strictPlan
      , nestedPlan = nestedPlanValue
      , refutablePatternPlan = refutablePlan
      , joinPlan = joinPlanValue
      , grandTotal = total
      }

render :: Show a => String -> Maybe a -> String
render label value =
  case value of
    Just v -> printf "%s = Just %s" label (show v)
    Nothing -> printf "%s = Nothing" label

main :: IO ()
main = do
  putStrLn "ApplicativeDo compact+advanced demo"
  putStrLn (render "pureApplicativeExample" pureApplicativeExample)
  putStrLn (render "mixedDependencyExample" mixedDependencyExample)
  putStrLn (render "bodyStmtExample" bodyStmtExample)
  putStrLn (render "strictPatternExample" strictPatternExample)
  putStrLn (render "nestedExample" nestedExample)
  putStrLn (render "refutablePatternExample" refutablePatternExample)
  putStrLn (render "joinExample" joinExample)
  putStrLn (render "combinedReport" combinedReport)
