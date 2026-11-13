module Text.Types
  ( Symbol (..)
  , Punctuation (..)
  , Word (..)
  , Sentence (..)
  , Document (..)
  ) where

import Prelude hiding (Word)
import Data.Text (Text)

newtype Symbol = Symbol
  { unSymbol :: Char
  } deriving (Eq, Ord, Show)

data Punctuation
  = Period
  | Exclamation
  | Question
  | Comma
  | Semicolon
  | Colon
  | Dash
  | Quote
  | OpenParen
  | CloseParen
  | OtherPunctuation Char
  deriving (Eq, Ord, Show)

newtype Word = Word
  { unWord :: Text
  } deriving (Eq, Ord, Show)

data Sentence = Sentence
  { sentenceWords :: [Word]
  , sentenceEnd   :: Punctuation
  } deriving (Eq, Show)

newtype Document = Document
  { documentSentences :: [Sentence]
  } deriving (Eq, Show)
