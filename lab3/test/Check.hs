{-# LANGUAGE OverloadedStrings #-}

module Main where

import Prelude hiding (Word)

import Control.Monad (unless)

import Text.Analysis
import Text.Normalize
import Text.Tokenize
import Text.Types

main :: IO ()
main = do
  results <- sequence
    [ check "normalizes tabs and spaces"
        (normalizeWhitespace "a\t\tb   c\n d" == "a b c d")

    , check "splits into sentences"
        (length (documentSentences (toDocument "One. Two! Three?")) == 3)

    , check "word only in first sentence"
        (findWordOnlyInFirst (toDocument "alpha beta gamma. beta delta. gamma epsilon.")
          == Just (Word "alpha"))

    , check "comparison is case-insensitive"
        (findWordsOnlyInFirst (toDocument "Haskell is pure. haskell is lazy.")
          == [Word "pure"])

    , check "duplicates in the first sentence are reported once"
        (findWordsOnlyInFirst (toDocument "alpha alpha beta. gamma.")
          == [Word "alpha", Word "beta"])

    , check "punctuation is stripped from words"
        (findWordsOnlyInFirst (toDocument "Hello, world! Hello again.")
          == [Word "world"])

    , check "single sentence: every word qualifies"
        (findWordsOnlyInFirst (toDocument "one two three.")
          == [Word "one", Word "two", Word "three"])

    , check "empty document has no result"
        (findWordOnlyInFirst (toDocument "") == Nothing)
    ]
  unless (and results) (ioError (userError "text checks failed"))
  putStrLn ""
  putStrLn "ALL TEXT CHECKS PASSED"

check :: String -> Bool -> IO Bool
check label ok = do
  putStrLn ((if ok then "[PASS] " else "[FAIL] ") ++ label)
  pure ok
