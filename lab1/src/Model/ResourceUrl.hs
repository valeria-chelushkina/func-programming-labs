module Model.ResourceUrl
  ( ResourceUrl (..)
  , ResourceUrlDraft (..)
  ) where

import Data.Text (Text)
import Data.Word (Word32)

data ResourceUrl = ResourceUrl
  { urlId         :: Word32
  , urlResourceId :: Word32
  , urlAddress    :: Text
  , urlLabel      :: Maybe Text
  , urlPrimary    :: Bool
  } deriving (Show, Eq)

data ResourceUrlDraft = ResourceUrlDraft
  { urlDraftAddress :: Text
  , urlDraftLabel   :: Maybe Text
  , urlDraftPrimary :: Bool
  } deriving (Show, Eq)
