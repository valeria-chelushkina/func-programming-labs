module Model.Lookup
  ( Kind (..)
  , Purpose (..)
  , UsageCondition (..)
  ) where

import Data.Text (Text)
import Data.Word (Word32)

data Kind = Kind
  { kindId   :: Word32
  , kindName :: Text
  } deriving (Show, Eq)

data Purpose = Purpose
  { purposeId   :: Word32
  , purposeName :: Text
  } deriving (Show, Eq)

data UsageCondition = UsageCondition
  { conditionId          :: Word32
  , conditionName        :: Text
  , conditionDescription :: Maybe Text
  } deriving (Show, Eq)
