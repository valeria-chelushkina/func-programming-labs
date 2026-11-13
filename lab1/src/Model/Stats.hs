{-# LANGUAGE OverloadedStrings #-}

module Model.Stats
  ( UsageAction (..)
  , actionToText
  , actionFromText
  , UsageRecord (..)
  , ResourceUsage (..)
  , TopResource (..)
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Time.LocalTime (LocalTime)
import Data.Word (Word32)

data UsageAction = View | Download | Open
  deriving (Show, Eq, Enum, Bounded)

actionToText :: UsageAction -> Text
actionToText View     = "view"
actionToText Download = "download"
actionToText Open     = "open"

actionFromText :: Text -> Either String UsageAction
actionFromText "view"     = Right View
actionFromText "download" = Right Download
actionFromText "open"     = Right Open
actionFromText other      = Left ("unknown action: " <> T.unpack other)

data UsageRecord = UsageRecord
  { usageUserId     :: Word32
  , usageResourceId :: Word32
  , usageAction     :: UsageAction
  , usageMinutes    :: Int
  } deriving (Show, Eq)

data ResourceUsage = ResourceUsage
  { ruUses         :: Int
  , ruUniqueUsers  :: Int
  , ruTotalMinutes :: Int
  , ruLastUsed     :: Maybe LocalTime
  } deriving (Show, Eq)

data TopResource = TopResource
  { trName :: Text
  , trUses :: Int
  } deriving (Show, Eq)
