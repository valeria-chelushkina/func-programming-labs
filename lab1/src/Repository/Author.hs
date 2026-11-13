{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Repository.Author
  ( findAuthorsByResource
  , insertAuthor
  , updateAuthor
  ) where

import Control.Monad (void)
import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn, MySQLValue (..), OK (..), Query, execute)
import Model.Author (Author (..), AuthorDraft (..))
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

insertAuthor :: MySQLConn -> AuthorDraft -> IO Word32
insertAuthor conn d = do
  ok <- execute conn insertSql (authorParams d)
  pure (fromIntegral (okLastInsertID ok))

updateAuthor :: MySQLConn -> Word32 -> AuthorDraft -> IO ()
updateAuthor conn aid d =
  void $ execute conn updateSql (authorParams d ++ [MySQLInt32U aid])

insertSql :: Query
insertSql = "INSERT INTO authors (full_name, email, affiliation) VALUES (?, ?, ?)"

updateSql :: Query
updateSql = "UPDATE authors SET full_name = ?, email = ?, affiliation = ? WHERE id = ?"

authorParams :: AuthorDraft -> [MySQLValue]
authorParams d =
  [ MySQLText (authorDraftName d)
  , maybe MySQLNull MySQLText (authorDraftEmail d)
  , maybe MySQLNull MySQLText (authorDraftAffiliation d)
  ]
