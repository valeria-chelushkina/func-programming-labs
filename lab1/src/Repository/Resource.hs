{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-orphans #-}

-- | @resources@ table mapping.
--
-- The instances are orphans on purpose: 'Model.Resource' stays free of the
-- MySQL driver, and every entity gets its own small mapping module.
module Repository.Resource () where

import Database.MySQL.Base (MySQLValue (..))
import Model.Resource (Resource (..))
import Repository.Class (FromRow (..), Repository (..), maybeDay)

-- The order of patterns must match 'columnList' below.
instance FromRow Resource where
  fromRow [ MySQLInt32U i, MySQLText n, MySQLText a
          , MySQLInt32U k, MySQLInt32U p, MySQLInt32U c
          , MySQLDate o, MySQLText t, v ] =
    Resource i n a k p c o t <$> maybeDay v
  fromRow r = Left ("Resource: unexpected row shape: " <> show r)

instance Repository Resource where
  tableName  _ = "resources"
  columnList _ =
    [ "id", "name", "annotation", "kind_id", "purpose_id"
    , "condition_id", "opened_on", "term_text", "valid_until" ]
