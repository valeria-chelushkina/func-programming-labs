module Model.Filters
  ( ResourceFilter (..)
  , emptyFilter
  ) where

import qualified Data.Text as T
import Data.Text (Text)
import Data.Word (Word32)

data ResourceFilter = ResourceFilter
  { rfText      :: Text
  , rfKindId    :: Maybe Word32
  , rfPurposeId :: Maybe Word32
  , rfAuthorId  :: Maybe Word32
  } deriving (Show, Eq)

emptyFilter :: ResourceFilter
emptyFilter = ResourceFilter
  { rfText      = T.empty
  , rfKindId    = Nothing
  , rfPurposeId = Nothing
  , rfAuthorId  = Nothing
  }
