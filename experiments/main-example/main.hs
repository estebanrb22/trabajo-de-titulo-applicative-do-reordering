{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD
import qualified Numeric.Probability.Distribution as Dist

instance CD.CommutativeMonad (Dist.T Rational)
 
data Preparation = Low | High
  deriving (Eq, Ord, Show)

data Difficulty = Easy | Hard
  deriving (Eq, Ord, Show)

data Result = Fail | Pass
  deriving (Eq, Ord, Show)

quizGiven :: Preparation -> Dist.T Rational Result
quizGiven Low = Dist.choose (1 / 4) Pass Fail
quizGiven High = Dist.choose (3 / 4) Pass Fail

examGiven :: Preparation -> Difficulty -> Dist.T Rational Result
examGiven Low Easy = Dist.choose (1 / 2) Pass Fail
examGiven Low Hard = Dist.choose (1 / 4) Pass Fail
examGiven High Easy = Dist.choose (3 / 4) Pass Fail
examGiven High Hard = Dist.choose (1 / 2) Pass Fail

studentResults :: Dist.T Rational (Preparation, Result, Difficulty, Result)
studentResults = CD.do
  preparation <- Dist.uniform [Low, High]
  quiz <- quizGiven preparation
  difficulty <- Dist.uniform [Easy, Hard]
  finalExam <- examGiven preparation difficulty
  CD.return (preparation, quiz, difficulty, finalExam)

main :: IO ()
main = print (Dist.norm studentResults)
