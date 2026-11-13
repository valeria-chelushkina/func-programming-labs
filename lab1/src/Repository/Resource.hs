{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Repository.Resource
  ( insertResource
  , updateResource
  ) where

import Control.Monad (void)
import Data.Word (Word32)
import Database.MySQL.Base hiding (withTransaction)
import Db.Connection (withTransaction)
import Model.Resource (Resource (..), ResourceDraft (..))
import Model.ResourceUrl (ResourceUrlDraft (..))
import Repository.Class (FromRow (..), Repository (..), maybeDay)

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
  primaryKey _ = "id"

-- | Insert the resource and its authors/URLs atomically.
insertResource :: MySQLConn -> ResourceDraft -> IO Word32
insertResource conn d = withTransaction conn $ do
  ok <- execute conn insertSql (draftParams d)
  let rid = fromIntegral (okLastInsertID ok)
  replaceAuthors conn rid (draftAuthorIds d)
  replaceUrls conn rid (draftUrls d)
  pure rid

-- | Update the resource and replace its authors/URLs atomically.
updateResource :: MySQLConn -> Word32 -> ResourceDraft -> IO ()
updateResource conn rid d = withTransaction conn $ do
  void $ execute conn updateSql (draftParams d ++ [MySQLInt32U rid])
  replaceAuthors conn rid (draftAuthorIds d)
  replaceUrls conn rid (draftUrls d)

replaceAuthors :: MySQLConn -> Word32 -> [Word32] -> IO ()
replaceAuthors conn rid authorIds = do
  void $ execute conn deleteAuthorsSql [MySQLInt32U rid]
  mapM_ (insertAuthor conn rid) authorIds

insertAuthor :: MySQLConn -> Word32 -> Word32 -> IO ()
insertAuthor conn rid aid =
  void $ execute conn insertAuthorSql [MySQLInt32U rid, MySQLInt32U aid]

replaceUrls :: MySQLConn -> Word32 -> [ResourceUrlDraft] -> IO ()
replaceUrls conn rid urls = do
  void $ execute conn deleteUrlsSql [MySQLInt32U rid]
  mapM_ (insertUrl conn rid) urls

insertUrl :: MySQLConn -> Word32 -> ResourceUrlDraft -> IO ()
insertUrl conn rid u =
  void $ execute conn insertUrlSql
    [ MySQLInt32U rid
    , MySQLText (urlDraftAddress u)
    , maybe MySQLNull MySQLText (urlDraftLabel u)
    , MySQLInt8 (if urlDraftPrimary u then 1 else 0)
    ]

insertSql :: Query
insertSql = "INSERT INTO resources (name, annotation, kind_id, purpose_id, condition_id, opened_on, term_text, valid_until) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"

updateSql :: Query
updateSql = "UPDATE resources SET name = ?, annotation = ?, kind_id = ?, purpose_id = ?, condition_id = ?, opened_on = ?, term_text = ?, valid_until = ? WHERE id = ?"

deleteAuthorsSql :: Query
deleteAuthorsSql = "DELETE FROM resource_authors WHERE resource_id = ?"

insertAuthorSql :: Query
insertAuthorSql = "INSERT INTO resource_authors (resource_id, author_id) VALUES (?, ?)"

deleteUrlsSql :: Query
deleteUrlsSql = "DELETE FROM resource_urls WHERE resource_id = ?"

insertUrlSql :: Query
insertUrlSql = "INSERT INTO resource_urls (resource_id, url, label, is_primary) VALUES (?, ?, ?, ?)"

draftParams :: ResourceDraft -> [MySQLValue]
draftParams d =
  [ MySQLText (draftName d)
  , MySQLText (draftAnnotation d)
  , MySQLInt32U (draftKindId d)
  , MySQLInt32U (draftPurposeId d)
  , MySQLInt32U (draftConditionId d)
  , MySQLDate (draftOpenedOn d)
  , MySQLText (draftTermText d)
  , maybe MySQLNull MySQLDate (draftValidUntil d)
  ]
