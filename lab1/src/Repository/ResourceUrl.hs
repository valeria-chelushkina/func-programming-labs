{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Repository.ResourceUrl
  ( findUrlsByResource
  ) where

import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn, MySQLValue (..))
import Model.ResourceUrl (ResourceUrl (..))
import Repository.Class
  ( FromRow (..)
  , Repository (..)
  , boolValue
  , maybeText
  , selectRows
  )

instance FromRow ResourceUrl where
  fromRow [ MySQLInt32U i, MySQLInt32U rid, MySQLText u, l, b ] =
    ResourceUrl i rid u <$> maybeText l <*> boolValue b
  fromRow r = Left ("ResourceUrl: unexpected row shape: " <> show r)

instance Repository ResourceUrl where
  tableName  _ = "resource_urls"
  columnList _ = [ "id", "resource_id", "url", "label", "is_primary" ]
  primaryKey _ = "id"

findUrlsByResource :: MySQLConn -> Word32 -> IO [ResourceUrl]
findUrlsByResource conn rid =
  selectRows conn
    "SELECT id, resource_id, url, label, is_primary \
    \FROM resource_urls \
    \WHERE resource_id = ? \
    \ORDER BY is_primary DESC, id"
    [MySQLInt32U rid]
