{-# LANGUAGE OverloadedStrings #-}

module Text.Tokenize
  ( toDocument
  , toSentence
  , toSentenceWith
  , splitSentences
  , cleanWord
  ) where

import Prelude hiding (Word)

import Data.Char (isAlpha, isDigit, isLower, isSpace)
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import qualified Data.Text as T

import Text.Types

toDocument :: Text -> Document
toDocument =
  Document
    . map (\(t, p) -> toSentenceWith p t)
    . filter (\(t, _) -> not (T.null (T.strip t)))
    . splitSentences

toSentence :: Text -> Sentence
toSentence = toSentenceWith Period

toSentenceWith :: Punctuation -> Text -> Sentence
toSentenceWith p t =
  Sentence
    (map Word (filter (not . T.null) (map cleanWord (T.words t))))
    p

splitSentences :: Text -> [(Text, Punctuation)]
splitSentences = go [] [] . T.unpack
  where
    go acc cur [] =
      let t = T.pack (reverse cur)
       in if T.null (T.strip t)
            then reverse acc
            else reverse ((t, NoPunctuation) : acc)

    go acc cur (c : cs)
      | c `elem` (".!?" :: String) =
          if endsSentence c cur cs
            then go ((T.pack (reverse (c : cur)), punctuation c) : acc) [] cs
            else go acc (c : cur) cs
      | otherwise =
          go acc (c : cur) cs

endsSentence :: Char -> String -> String -> Bool
endsSentence '.' cur rest =
  not (isDecimal || isAbbreviation || (isSingleLetter && nextIsLower))
  where
    isDecimal = case cur of
      (d : _) -> isDigit d && case rest of
        (r : _) -> isDigit r
        []      -> False
      [] -> False

    token = lastToken (reverse cur)

    isAbbreviation =
      Set.member (T.toCaseFold (T.pack token)) abbreviations

    isSingleLetter = length token == 1

    nextIsLower = case dropWhile isSpace rest of
      (r : _) -> isLower r
      []      -> False
endsSentence _ _ _ = True

punctuation :: Char -> Punctuation
punctuation '.' = Period
punctuation '!' = Exclamation
punctuation '?' = Question
punctuation c   = OtherPunctuation c

lastToken :: String -> String
lastToken = reverse . takeWhile (\c -> isAlpha c || c == '.') . reverse

abbreviations :: Set Text
abbreviations = Set.fromList (map T.toCaseFold
  [ "т.д", "т.ін", "т.п", "т.зв", "напр", "див", "рис", "табл", "ст"
  , "e.g", "i.e", "etc", "vs", "prof", "dr"
  ])

cleanWord :: Text -> Text
cleanWord = T.dropAround isPunctuation
  where
    isPunctuation c = c `elem` (".,;:!?…\"'()[]{}—–" :: String)
