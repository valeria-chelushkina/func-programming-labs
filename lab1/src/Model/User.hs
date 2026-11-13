{-# LANGUAGE OverloadedStrings #-}

module Model.User
  ( Role (..)
  , roleToText
  , roleFromText
  , User (..)
  , UserDraft (..)
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Word (Word32)

data Role = Student | Teacher | Staff
  deriving (Show, Eq, Enum, Bounded)

roleToText :: Role -> Text
roleToText Student = "student"
roleToText Teacher = "teacher"
roleToText Staff   = "staff"

roleFromText :: Text -> Either String Role
roleFromText "student" = Right Student
roleFromText "teacher" = Right Teacher
roleFromText "staff"   = Right Staff
roleFromText other     = Left ("unknown role: " <> T.unpack other)

data User = User
  { userId         :: Word32
  , userName       :: Text
  , userEmail      :: Text
  , userRole       :: Role
  , userDepartment :: Maybe Text
  } deriving (Show, Eq)

data UserDraft = UserDraft
  { userDraftName       :: Text
  , userDraftEmail      :: Text
  , userDraftRole       :: Role
  , userDraftDepartment :: Maybe Text
  } deriving (Show, Eq)
