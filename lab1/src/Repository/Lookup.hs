{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Repository.Lookup () where

import Database.MySQL.Base (MySQLValue (..))
import Model.Lookup (Kind (..), Purpose (..), UsageCondition (..))
import Repository.Class (FromRow (..), Repository (..), maybeText)

instance FromRow Kind where
  fromRow [ MySQLInt32U i, MySQLText n ] = Right (Kind i n)
  fromRow r = Left ("Kind: unexpected row shape: " <> show r)

instance Repository Kind where
  tableName  _ = "kinds"
  columnList _ = [ "id", "name" ]
  primaryKey _ = "id"

instance FromRow Purpose where
  fromRow [ MySQLInt32U i, MySQLText n ] = Right (Purpose i n)
  fromRow r = Left ("Purpose: unexpected row shape: " <> show r)

instance Repository Purpose where
  tableName  _ = "purposes"
  columnList _ = [ "id", "name" ]
  primaryKey _ = "id"

instance FromRow UsageCondition where
  fromRow [ MySQLInt32U i, MySQLText n, d ] =
    UsageCondition i n <$> maybeText d
  fromRow r = Left ("UsageCondition: unexpected row shape: " <> show r)

instance Repository UsageCondition where
  tableName  _ = "usage_conditions"
  columnList _ = [ "id", "name", "description" ]
  primaryKey _ = "id"
