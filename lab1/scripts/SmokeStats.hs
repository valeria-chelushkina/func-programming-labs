{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Manual smoke test for users + usage statistics.
--
-- Run from lab1/:
--   cabal exec -- runghc -isrc scripts\SmokeStats.hs
module Main where

import Control.Exception (finally)
import Control.Monad (unless)
import Data.Maybe (isJust)
import Data.Time.Calendar (fromGregorian)
import Database.MySQL.Base (MySQLConn, execute_)
import Data.Word (Word32)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

import Db.Config (defaultConfig)
import Db.Connection (withConnection)
import Model.Resource (ResourceDraft (..))
import Model.ResourceUrl (ResourceUrlDraft (..))
import Model.Stats (ResourceUsage (..), TopResource (..), UsageAction (..), UsageRecord (..))
import Model.User (Role (..), UserDraft (..))
import Service.Resource (createResource)
import Service.Stats
import Service.User (createUser)

main :: IO ()
main = withConnection defaultConfig $ \conn ->
  (do cleanup conn
      u1 <- mustUser conn "Smoke Stats User One" "smoke.stats.one@example.org"
      u2 <- mustUser conn "Smoke Stats User Two" "smoke.stats.two@example.org"
      rid <- mustResource conn
      checks conn u1 u2 rid
      TIO.putStrLn ""
      TIO.putStrLn "ALL STATS CHECKS PASSED")
    `finally` cleanup conn

checks :: MySQLConn -> Word32 -> Word32 -> Word32 -> IO ()
checks conn u1 u2 rid = do
  TIO.putStrLn "1. record usage"
  r1 <- recordUsage conn (usage rid u1 View 10)
  check "record view 10 min" (isRight r1)
  r2 <- recordUsage conn (usage rid u2 View 20)
  check "record view 20 min" (isRight r2)
  r3 <- recordUsage conn (usage rid u1 Download 5)
  check "record download 5 min" (isRight r3)

  TIO.putStrLn "2. invalid records"
  neg <- recordUsage conn (usage rid u1 Open (-1))
  check "negative minutes rejected" (isLeft neg)
  badUser <- recordUsage conn (usage rid 999999 Open 5)
  check "unknown user rejected" (isLeft badUser)

  TIO.putStrLn "3. resource summary"
  ru <- resourceUsage conn rid
  check "uses = 3" (ruUses ru == 3)
  check "unique users = 2" (ruUniqueUsers ru == 2)
  check "total minutes = 35" (ruTotalMinutes ru == 35)
  check "last used is set" (isJust (ruLastUsed ru))

  TIO.putStrLn "4. top resources"
  top <- topResources conn 100
  check "resource is in the report"
    (any (\t -> trName t == "Smoke Stats Resource" && trUses t == 3) top)

  TIO.putStrLn "5. per-user counts"
  c1 <- userUsageCount conn u1
  c2 <- userUsageCount conn u2
  check "user one has 2 records" (c1 == 2)
  check "user two has 1 record" (c2 == 1)

usage :: Word32 -> Word32 -> UsageAction -> Int -> UsageRecord
usage rid uid action minutes = UsageRecord
  { usageUserId     = uid
  , usageResourceId = rid
  , usageAction     = action
  , usageMinutes    = minutes
  }

mustUser :: MySQLConn -> T.Text -> T.Text -> IO Word32
mustUser conn name email = do
  r <- createUser conn UserDraft
    { userDraftName       = name
    , userDraftEmail      = email
    , userDraftRole       = Student
    , userDraftDepartment = Just "Dept"
    }
  case r of
    Left err -> ioError (userError ("create user failed: " <> err))
    Right i  -> pure i

mustResource :: MySQLConn -> IO Word32
mustResource conn = do
  execute_ conn "INSERT INTO kinds (id, name) VALUES (9701, 'Smoke Stats Kind')"
  execute_ conn "INSERT INTO purposes (id, name) VALUES (9702, 'Smoke Stats Purpose')"
  execute_ conn "INSERT INTO usage_conditions (id, name) VALUES (9703, 'Smoke Stats Condition')"
  execute_ conn "INSERT INTO authors (id, full_name) VALUES (9704, 'Smoke Stats Author')"
  r <- createResource conn ResourceDraft
    { draftName        = "Smoke Stats Resource"
    , draftAnnotation  = "Statistics test"
    , draftKindId      = 9701
    , draftPurposeId   = 9702
    , draftConditionId = 9703
    , draftOpenedOn    = fromGregorian 2024 5 1
    , draftTermText    = "1 year"
    , draftValidUntil  = Nothing
    , draftAuthorIds   = [9704]
    , draftUrls        = [ResourceUrlDraft "https://example.org/stats" Nothing True]
    }
  case r of
    Left err -> ioError (userError ("create resource failed: " <> err))
    Right i  -> pure i

check :: String -> Bool -> IO ()
check label ok = do
  TIO.putStrLn ((if ok then "[PASS] " else "[FAIL] ") <> T.pack label)
  unless ok (ioError (userError ("check failed: " <> label)))

isLeft :: Either a b -> Bool
isLeft (Left _)  = True
isLeft (Right _) = False

isRight :: Either a b -> Bool
isRight = not . isLeft

cleanup :: MySQLConn -> IO ()
cleanup conn = do
  execute_ conn "DELETE FROM usage_stats WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'smoke.stats.%')"
  execute_ conn "DELETE FROM resources WHERE name = 'Smoke Stats Resource'"
  execute_ conn "DELETE FROM users WHERE email LIKE 'smoke.stats.%'"
  execute_ conn "DELETE FROM authors WHERE id = 9704"
  execute_ conn "DELETE FROM kinds WHERE id = 9701"
  execute_ conn "DELETE FROM purposes WHERE id = 9702"
  execute_ conn "DELETE FROM usage_conditions WHERE id = 9703"
  pure ()
