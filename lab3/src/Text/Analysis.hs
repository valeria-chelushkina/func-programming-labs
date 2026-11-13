{-# LANGUAGE OverloadedStrings #-}

module Text.Analysis
  ( findWordOnlyInFirst
  , findWordsOnlyInFirst
  , wordKey
  ) where

import Prelude hiding (Word)

import Data.Maybe (listToMaybe)
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T

import Text.Types
findWordOnlyInFirst :: Document -> Maybe Word
findWordOnlyInFirst = listToMaybe . findWordsOnlyInFirst

findWordsOnlyInFirst :: Document -> [Word]
findWordsOnlyInFirst (Document []) = []
findWordsOnlyInFirst (Document (firstSentence : otherSentences)) =
  filter isOnlyInFirst (dedupeOn wordKey (sentenceWords firstSentence))
  where
    otherKeys :: Set Text
    otherKeys = Set.fromList
      [ wordKey w
      | s <- otherSentences
      , w <- sentenceWords s
      ]

    isOnlyInFirst :: Word -> Bool
    isOnlyInFirst w = not (Set.member (wordKey w) otherKeys)

wordKey :: Word -> Text
wordKey = T.toCaseFold . unWord

dedupeOn :: Ord k => (a -> k) -> [a] -> [a]
dedupeOn key = go Set.empty
  where
    go _ [] = []
    go seen (x : xs)
      | Set.member (key x) seen = go seen xs
      | otherwise               = x : go (Set.insert (key x) seen) xs
