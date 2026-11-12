{-# LANGUAGE OverloadedStrings #-}

-- | Pure domain types. No database, no IO.
module Model.Resource
  ( Resource (..)
  ) where

import Data.Text (Text)
import Data.Time.Calendar (Day)
import Data.Word (Word32)

-- | One row of the @resources@ table.
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
