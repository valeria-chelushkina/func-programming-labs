module Model.Author
  ( Author (..)
  ) where

import Data.Text (Text)
import Data.Word (Word32)

data Author = Author
  { authorId          :: Word32
  , authorName        :: Text
  , authorEmail       :: Maybe Text
  , authorAffiliation :: Maybe Text
  } deriving (Show, Eq)
