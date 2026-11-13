{-# LANGUAGE TypeApplications #-}

module Service.Lookup
  ( listKinds
  , getKind
  , listPurposes
  , getPurpose
  , listConditions
  , getCondition
  ) where

import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn)
import Model.Lookup (Kind, Purpose, UsageCondition)
import Repository.Class (Repository (..))
import Repository.Lookup ()

listKinds :: MySQLConn -> IO [Kind]
listKinds conn = findAll @Kind conn

getKind :: MySQLConn -> Word32 -> IO (Maybe Kind)
getKind conn i = findById @Kind conn i

listPurposes :: MySQLConn -> IO [Purpose]
listPurposes conn = findAll @Purpose conn

getPurpose :: MySQLConn -> Word32 -> IO (Maybe Purpose)
getPurpose conn i = findById @Purpose conn i

listConditions :: MySQLConn -> IO [UsageCondition]
listConditions conn = findAll @UsageCondition conn

getCondition :: MySQLConn -> Word32 -> IO (Maybe UsageCondition)
getCondition conn i = findById @UsageCondition conn i
