{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Repository.Author
  ( findAuthorsByResource
  ) where

import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn, MySQLValue (..))
import Model.Author (Author (..))
import Repository.Class
  ( FromRow (..)
  , Repository (..)
  , maybeText
  , selectRows
  )

instance FromRow Author where
  fromRow [ MySQLInt32U i, MySQLText n, e, a ] =
    Author i n <$> maybeText e <*> maybeText a
  fromRow r = Left ("Author: unexpected row shape: " <> show r)

instance Repository Author where
  tableName  _ = "authors"
  columnList _ = [ "id", "full_name", "email", "affiliation" ]
  primaryKey _ = "id"

findAuthorsByResource :: MySQLConn -> Word32 -> IO [Author]
findAuthorsByResource conn rid =
  selectRows conn
    "SELECT a.id, a.full_name, a.email, a.affiliation \
    \FROM authors a \
    \JOIN resource_authors ra ON ra.author_id = a.id \
    \WHERE ra.resource_id = ? \
    \ORDER BY a.full_name"
    [MySQLInt32U rid]
