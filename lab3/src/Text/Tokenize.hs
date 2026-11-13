{-# LANGUAGE OverloadedStrings #-}

module Text.Tokenize
  ( toDocument
  , toSentence
  , cleanWord
  ) where

import Prelude hiding (Word)
import Data.Text (Text)
import qualified Data.Text as T

import Text.Types

toDocument :: Text -> Document
toDocument =
  Document
    . map toSentence
    . filter (not . T.null)
    . map T.strip
    . T.split isSentenceEnd

isSentenceEnd :: Char -> Bool
isSentenceEnd c = c `elem` (".!?" :: String)

-- | Split one sentence into cleaned words.
--
-- The sentence terminator is not preserved by 'T.split', so the constructor
-- currently stores 'Period' for every sentence. Preserving the real
-- terminator is a possible refinement.
toSentence :: Text -> Sentence
toSentence t =
  Sentence
    (map Word (filter (not . T.null) (map cleanWord (T.words t))))
    Period

-- | Remove punctuation around a word, keeping the inner characters.
cleanWord :: Text -> Text
cleanWord = T.dropAround isPunctuation
  where
    isPunctuation c = c `elem` (".,;:!?…\"'()[]{}—–" :: String)
