{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Repository.Class
  ( FromRow (..)
  , Repository (..)
  , maybeDay
  , maybeText
  , boolValue
  , selectRows
  ) where

import qualified Data.ByteString.Lazy as BL
import Data.Proxy (Proxy (..))
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Data.Time.Calendar (Day)
import Data.Word (Word32)
import Database.MySQL.Base
import qualified System.IO.Streams as Streams

class FromRow a where
  fromRow :: [MySQLValue] -> Either String a

class FromRow a => Repository a where
  tableName  :: Proxy a -> Text
  columnList :: Proxy a -> [Text]
  primaryKey :: Proxy a -> Text

  findAll :: MySQLConn -> IO [a]
  findAll conn =
    let p = Proxy @a
     in selectRows conn (selectAllSql (tableName p) (columnList p)) []

  findById :: MySQLConn -> Word32 -> IO (Maybe a)
  findById conn i = do
    let p = Proxy @a
    rs <- selectRows conn
            (selectByIdSql (tableName p) (columnList p) (primaryKey p))
            [MySQLInt32U i]
    case rs of
      []    -> pure Nothing
      (r:_) -> pure (Just r)

  deleteById :: MySQLConn -> Word32 -> IO ()
  deleteById conn i = do
    let p   = Proxy @a
        sql = "DELETE FROM " <> tableName p
                          <> " WHERE " <> primaryKey p <> " = ?"
    _ <- execute conn (toQuery sql) [MySQLInt32U i]
    pure ()

-- | Helper for nullable DATE columns used by several entities.
maybeDay :: MySQLValue -> Either String (Maybe Day)
maybeDay MySQLNull     = Right Nothing
maybeDay (MySQLDate d) = Right (Just d)
maybeDay v             = Left ("expected DATE or NULL, got " <> show v)

-- | Helper for nullable TEXT columns.
maybeText :: MySQLValue -> Either String (Maybe Text)
maybeText MySQLNull     = Right Nothing
maybeText (MySQLText t) = Right (Just t)
maybeText v             = Left ("expected TEXT or NULL, got " <> show v)

boolValue :: MySQLValue -> Either String Bool
boolValue (MySQLInt8 n)   = Right (n /= 0)
boolValue (MySQLInt8U n)  = Right (n /= 0)
boolValue (MySQLInt16 n)  = Right (n /= 0)
boolValue (MySQLInt16U n) = Right (n /= 0)
boolValue (MySQLInt32 n)  = Right (n /= 0)
boolValue (MySQLInt32U n) = Right (n /= 0)
boolValue (MySQLInt64 n)  = Right (n /= 0)
boolValue (MySQLInt64U n) = Right (n /= 0)
boolValue v               = Left ("expected BOOLEAN, got " <> show v)

selectRows :: FromRow a => MySQLConn -> Text -> [MySQLValue] -> IO [a]
selectRows conn sql params = do
  (_, rows) <- query conn (toQuery sql) params
  xs <- Streams.toList rows
  case traverse fromRow xs of
    Left err -> ioError (userError err)
    Right rs -> pure rs

selectAllSql :: Text -> [Text] -> Text
selectAllSql tbl cols =
  "SELECT " <> T.intercalate ", " cols <> " FROM " <> tbl

selectByIdSql :: Text -> [Text] -> Text -> Text
selectByIdSql tbl cols pk =
  selectAllSql tbl cols <> " WHERE " <> pk <> " = ? LIMIT 1"

toQuery :: Text -> Query
toQuery = Query . BL.fromStrict . encodeUtf8
