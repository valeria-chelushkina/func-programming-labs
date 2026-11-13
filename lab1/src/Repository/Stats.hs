{-# LANGUAGE OverloadedStrings #-}

module Repository.Stats
  ( insertUsage
  , resourceUsage
  , topResources
  , userUsageCount
  , totalUsageCount
  ) where

import Control.Monad (void)
import qualified Data.Text as T
import Data.Time.LocalTime (LocalTime)
import Data.Word (Word32)
import Data.String (fromString)
import Database.MySQL.Base
import qualified System.IO.Streams as Streams

import Model.Stats
  ( ResourceUsage (..)
  , TopResource (..)
  , UsageRecord (..)
  , actionToText
  )
import Repository.Class (intValue)

insertUsage :: MySQLConn -> UsageRecord -> IO ()
insertUsage conn u =
  void $ execute conn
    "INSERT INTO usage_stats (user_id, resource_id, action, minutes) VALUES (?, ?, ?, ?)"
    [ MySQLInt32U (usageUserId u)
    , MySQLInt32U (usageResourceId u)
    , MySQLText (actionToText (usageAction u))
    , MySQLInt32 (fromIntegral (max 0 (usageMinutes u)))
    ]

resourceUsage :: MySQLConn -> Word32 -> IO ResourceUsage
resourceUsage conn rid = do
  (_, rows) <- query conn
    "SELECT COUNT(*), COUNT(DISTINCT user_id), \
    \CAST(COALESCE(SUM(minutes), 0) AS SIGNED), MAX(used_at) \
    \FROM usage_stats WHERE resource_id = ?"
    [MySQLInt32U rid]
  xs <- Streams.toList rows
  case xs of
    [row] -> either (ioError . userError) pure (decodeUsage row)
    _     -> ioError (userError "usage_stats: expected exactly one row")

decodeUsage :: [MySQLValue] -> Either String ResourceUsage
decodeUsage [uses, users, minutes, lastUsed] =
  ResourceUsage
    <$> intValue uses
    <*> intValue users
    <*> intValue minutes
    <*> maybeLocalTime lastUsed
decodeUsage row =
  Left ("usage_stats: unexpected row shape: " <> show row)

topResources :: MySQLConn -> Int -> IO [TopResource]
topResources conn limit = do
  let sql = "SELECT r.name, COUNT(*) AS uses \
            \FROM usage_stats s JOIN resources r ON r.id = s.resource_id \
            \GROUP BY r.id, r.name ORDER BY uses DESC, r.name LIMIT "
            <> T.pack (show (max 0 limit))
  (_, rows) <- query_ conn (fromString (T.unpack sql))
  xs <- Streams.toList rows
  case traverse decodeTop xs of
    Left err -> ioError (userError err)
    Right rs -> pure rs

decodeTop :: [MySQLValue] -> Either String TopResource
decodeTop [MySQLText name, uses] =
  TopResource name <$> intValue uses
decodeTop row =
  Left ("topResources: unexpected row shape: " <> show row)

userUsageCount :: MySQLConn -> Word32 -> IO Int
userUsageCount conn uid = do
  (_, rows) <- query conn
    "SELECT COUNT(*) FROM usage_stats WHERE user_id = ?"
    [MySQLInt32U uid]
  xs <- Streams.toList rows
  case xs of
    [[v]] -> either (ioError . userError) pure (intValue v)
    _     -> ioError (userError "usage_stats: expected exactly one count")

totalUsageCount :: MySQLConn -> IO Int
totalUsageCount conn = do
  (_, rows) <- query_ conn "SELECT COUNT(*) FROM usage_stats"
  xs <- Streams.toList rows
  case xs of
    [[v]] -> either (ioError . userError) pure (intValue v)
    _     -> ioError (userError "usage_stats: expected exactly one count")

maybeLocalTime :: MySQLValue -> Either String (Maybe LocalTime)
maybeLocalTime MySQLNull         = Right Nothing
maybeLocalTime (MySQLDateTime t) = Right (Just t)
maybeLocalTime v                 = Left ("expected DATETIME or NULL, got " <> show v)
