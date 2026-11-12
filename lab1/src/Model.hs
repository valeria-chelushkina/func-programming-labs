{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Domain types, type classes and their instances.
module Model
  ( Resource (..)
  , FromRow (..)
  , Repository (..)
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

-- | One row of the @resources@ table.
--
-- The field order matches 'columnList' for 'Resource' below.
data Resource = Resource
  { resId          :: Word32
  , resName        :: Text
  , resAnnotation  :: Text
  , resKindId      :: Word32
  , resPurposeId   :: Word32
  , resConditionId :: Word32
  , resOpenedOn    :: Day
  , resTermText    :: Text
  , resValidUntil  :: Maybe Day
  } deriving (Show, Eq)

-- | Decode one database row into a domain value.
--
-- Positional by design: the order of patterns must match the SELECT list.
class FromRow a where
  fromRow :: [MySQLValue] -> Either String a

instance FromRow Resource where
  fromRow [ MySQLInt32U i, MySQLText n, MySQLText a
          , MySQLInt32U k, MySQLInt32U p, MySQLInt32U c
          , MySQLDate o, MySQLText t, v ] =
    Resource i n a k p c o t <$> maybeDay v
  fromRow r = Left ("Resource: unexpected row shape: " <> show r)

maybeDay :: MySQLValue -> Either String (Maybe Day)
maybeDay MySQLNull     = Right Nothing
maybeDay (MySQLDate d) = Right (Just d)
maybeDay v             = Left ("expected DATE or NULL, got " <> show v)

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

instance Repository Resource where
  tableName  _ = "resources"
  columnList _ =
    [ "id", "name", "annotation", "kind_id", "purpose_id"
    , "condition_id", "opened_on", "term_text", "valid_until" ]
