module Model.Resource
  ( Resource (..)
  , ResourceDraft (..)
  , ResourceDetails (..)
  ) where

import Data.Text (Text)
import Data.Time.Calendar (Day)
import Data.Word (Word32)
import Model.Author (Author)
import Model.ResourceUrl (ResourceUrl, ResourceUrlDraft)

data Resource = Resource
  { resId          :: Word32
  , resName        :: Text
  , resAnnotation  :: Text
  , resKindId      :: Word32
  , resPurposeId   :: Word32
  , resConditionId :: Word32
  , resOpenedOn    :: Day
  , resTermText    :: Text
  , resValidUntil  :: Maybe Day
  } deriving (Show, Eq)

data ResourceDraft = ResourceDraft
  { draftName        :: Text
  , draftAnnotation  :: Text
  , draftKindId      :: Word32
  , draftPurposeId   :: Word32
  , draftConditionId :: Word32
  , draftOpenedOn    :: Day
  , draftTermText    :: Text
  , draftValidUntil  :: Maybe Day
  , draftAuthorIds   :: [Word32]
  , draftUrls        :: [ResourceUrlDraft]
  } deriving (Show, Eq)

data ResourceDetails = ResourceDetails
  { detailResource :: Resource
  , detailAuthors  :: [Author]
  , detailUrls     :: [ResourceUrl]
  } deriving (Show, Eq)
