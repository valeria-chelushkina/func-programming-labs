{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Manual smoke test for resource search.
--
-- Run from lab1/:
--   cabal exec -- runghc -isrc scripts\SmokeSearch.hs
module Main where

import Control.Exception (finally)
import Control.Monad (unless)
import Data.Time.Calendar (fromGregorian)
import Database.MySQL.Base (MySQLConn, execute_)
import Data.Word (Word32)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

import Db.Config (defaultConfig)
import Db.Connection (withConnection)
import Model.Filters (ResourceFilter (..), emptyFilter)
import Model.Resource (Resource (..), ResourceDraft (..))
import Model.ResourceUrl (ResourceUrlDraft (..))
import Service.Resource (createResource, searchResources)

main :: IO ()
main = withConnection defaultConfig $ \conn ->
  (do cleanup conn
      setup conn
      checks conn
      TIO.putStrLn ""
      TIO.putStrLn "ALL SEARCH CHECKS PASSED")
    `finally` cleanup conn

checks :: MySQLConn -> IO ()
checks conn = do
  TIO.putStrLn "1. empty filter"
  allRs <- searchResources conn emptyFilter
  check "empty filter returns all 3" (length allRs == 3)

  TIO.putStrLn "2. text search"
  neural <- searchResources conn emptyFilter { rfText = "neural" }
  check "name match is case-insensitive"
    (names neural == ["Smoke Search Neural Networks"])

  opt <- searchResources conn emptyFilter { rfText = "optimization" }
  check "annotation match works"
    (names opt == ["Smoke Search Databases"])

  partial <- searchResources conn emptyFilter { rfText = "Search" }
  check "partial match returns all"
    (length partial == 3)

  TIO.putStrLn "3. filters"
  byKind <- searchResources conn emptyFilter { rfKindId = Just 9401 }
  check "kind filter returns 2" (length byKind == 2)

  byPurpose <- searchResources conn emptyFilter { rfPurposeId = Just 9411 }
  check "purpose filter returns 2" (length byPurpose == 2)

  byAuthor <- searchResources conn emptyFilter { rfAuthorId = Just 9502 }
  check "author filter returns one"
    (names byAuthor == ["Smoke Search Databases"])

  combined <- searchResources conn emptyFilter
    { rfKindId = Just 9401, rfPurposeId = Just 9412 }
  check "combined filters"
    (names combined == ["Smoke Search Databases"])

  none <- searchResources conn emptyFilter { rfText = "no-such-text" }
  check "no matches returns empty list" (null none)

  blank <- searchResources conn emptyFilter { rfText = "   " }
  check "blank text is ignored" (length blank == 3)

names :: [Resource] -> [T.Text]
names = map resName

check :: String -> Bool -> IO ()
check label ok = do
  TIO.putStrLn ((if ok then "[PASS] " else "[FAIL] ") <> T.pack label)
  unless ok (ioError (userError ("check failed: " <> label)))

setup :: MySQLConn -> IO ()
setup conn = do
  execute_ conn "INSERT INTO kinds (id, name) VALUES (9401, 'Smoke Kind A'), (9402, 'Smoke Kind B')"
  execute_ conn "INSERT INTO purposes (id, name) VALUES (9411, 'Smoke Purpose A'), (9412, 'Smoke Purpose B')"
  execute_ conn "INSERT INTO usage_conditions (id, name) VALUES (9421, 'Smoke Condition')"
  execute_ conn "INSERT INTO authors (id, full_name) VALUES (9501, 'Smoke Search Author One')"
  execute_ conn "INSERT INTO authors (id, full_name) VALUES (9502, 'Smoke Search Author Two')"

  _ <- mustCreate conn ResourceDraft
    { draftName        = "Smoke Search Neural Networks"
    , draftAnnotation  = "Deep learning basics"
    , draftKindId      = 9401
    , draftPurposeId   = 9411
    , draftConditionId = 9421
    , draftOpenedOn    = fromGregorian 2024 1 10
    , draftTermText    = "1 year"
    , draftValidUntil  = Nothing
    , draftAuthorIds   = [9501]
    , draftUrls        = [ResourceUrlDraft "https://example.org/nn" Nothing True]
    }

  _ <- mustCreate conn ResourceDraft
    { draftName        = "Smoke Search Databases"
    , draftAnnotation  = "Query optimization techniques"
    , draftKindId      = 9401
    , draftPurposeId   = 9412
    , draftConditionId = 9421
    , draftOpenedOn    = fromGregorian 2024 2 20
    , draftTermText    = "2 years"
    , draftValidUntil  = Nothing
    , draftAuthorIds   = [9502]
    , draftUrls        = [ResourceUrlDraft "https://example.org/db" Nothing True]
    }

  _ <- mustCreate conn ResourceDraft
    { draftName        = "Smoke Search Haskell"
    , draftAnnotation  = "Functional programming"
    , draftKindId      = 9402
    , draftPurposeId   = 9411
    , draftConditionId = 9421
    , draftOpenedOn    = fromGregorian 2025 3 5
    , draftTermText    = "6 months"
    , draftValidUntil  = Nothing
    , draftAuthorIds   = [9501]
    , draftUrls        = [ResourceUrlDraft "https://example.org/hs" Nothing True]
    }
  pure ()

mustCreate :: MySQLConn -> ResourceDraft -> IO Word32
mustCreate conn d = do
  r <- createResource conn d
  case r of
    Left err -> ioError (userError ("create failed: " <> err))
    Right i  -> pure i

cleanup :: MySQLConn -> IO ()
cleanup conn = do
  execute_ conn "DELETE FROM resources WHERE name LIKE 'Smoke Search%'"
  execute_ conn "DELETE FROM authors WHERE id IN (9501, 9502)"
  execute_ conn "DELETE FROM kinds WHERE id IN (9401, 9402)"
  execute_ conn "DELETE FROM purposes WHERE id IN (9411, 9412)"
  execute_ conn "DELETE FROM usage_conditions WHERE id = 9421"
  pure ()
