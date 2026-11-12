{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Classes that describe how a domain type maps to a table.
module Repository.Class
  ( FromRow (..)
  , Repository (..)
  , maybeDay
  ) where

import qualified Data.ByteString.Lazy as BL
import Data.Proxy (Proxy (..))
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Data.Time.Calendar (Day)
import Database.MySQL.Base
import qualified System.IO.Streams as Streams

-- | Decode one database row into a domain value.
class FromRow a where
  fromRow :: [MySQLValue] -> Either String a

-- | Read operations shared by every entity.
class FromRow a => Repository a where
  tableName  :: Proxy a -> Text
  columnList :: Proxy a -> [Text]

  findAll :: MySQLConn -> IO [a]
  findAll conn = do
    let p   = Proxy @a
        sql = "SELECT " <> T.intercalate ", " (columnList p)
                       <> " FROM " <> tableName p
    (_, rows) <- query_ conn (Query (BL.fromStrict (encodeUtf8 sql)))
    xs <- Streams.toList rows
    case traverse fromRow xs of
      Left err -> ioError (userError err)
      Right rs -> pure rs

-- | Helper for nullable DATE columns used by several entities.
maybeDay :: MySQLValue -> Either String (Maybe Day)
maybeDay MySQLNull     = Right Nothing
maybeDay (MySQLDate d) = Right (Just d)
maybeDay v             = Left ("expected DATE or NULL, got " <> show v)
