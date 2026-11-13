module Model.Author
  ( Author (..)
  , AuthorDraft (..)
  ) where

import Data.Text (Text)
import Data.Word (Word32)

data Author = Author
  { authorId          :: Word32
  , authorName        :: Text
  , authorEmail       :: Maybe Text
  , authorAffiliation :: Maybe Text
  } deriving (Show, Eq)

data AuthorDraft = AuthorDraft
  { authorDraftName        :: Text
  , authorDraftEmail       :: Maybe Text
  , authorDraftAffiliation :: Maybe Text
  } deriving (Show, Eq)
