{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Manual smoke test for resource CRUD (there is no UI yet).
--
-- Run from lab1/:
--   cabal exec -- runghc -isrc scripts\SmokeCrud.hs
--
-- Uses temporary rows with ids 9001-9003 and 9101-9102, and removes
-- everything it created before and after the run.
module Main where

import Control.Exception (finally)
import Control.Monad (unless)
import Data.Maybe (isJust, isNothing, listToMaybe)
import Data.Time.Calendar (fromGregorian)
import Database.MySQL.Base (MySQLConn, execute_)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

import Db.Config (defaultConfig)
import Db.Connection (withConnection)
import Model.Resource (Resource (..), ResourceDetails (..), ResourceDraft (..))
import Model.ResourceUrl (ResourceUrl (..), ResourceUrlDraft (..))
import Repository.Class (Repository (..))
import Repository.Resource ()
import Repository.ResourceUrl ()
import Service.Resource

main :: IO ()
main = withConnection defaultConfig $ \conn ->
  (do cleanup conn
      setup conn
      checks conn
      TIO.putStrLn ""
      TIO.putStrLn "ALL CHECKS PASSED")
    `finally` cleanup conn

checks :: MySQLConn -> IO ()
checks conn = do
  TIO.putStrLn "1. validation: empty author list"
  r1 <- createResource conn draft { draftAuthorIds = [] }
  check "rejects empty author list" (isLeft r1)

  TIO.putStrLn "2. create"
  created <- createResource conn draft
  rid <- case created of
    Left err -> ioError (userError ("create failed: " <> err))
    Right i  -> pure i
  check "create returns an id" (rid > 0)

  TIO.putStrLn "3. read"
  d1 <- getResourceDetails conn rid
  check "resource exists" (isJust d1)
  check "2 authors linked" (maybe False ((== 2) . length . detailAuthors) d1)
  check "2 urls linked" (maybe False ((== 2) . length . detailUrls) d1)

  TIO.putStrLn "4. update"
  upd <- editResource conn rid draft
    { draftName      = "Smoke resource edited"
    , draftAuthorIds = [9102]
    , draftUrls      = [ ResourceUrlDraft "https://example.org/new" Nothing False ]
    }
  check "update succeeds" (isRight upd)

  d2 <- getResourceDetails conn rid
  check "name updated"
    (maybe False ((== "Smoke resource edited") . resName . detailResource) d2)
  check "authors replaced" (maybe False ((== 1) . length . detailAuthors) d2)
  check "urls replaced" (maybe False ((== 1) . length . detailUrls) d2)
  check "url normalised to primary"
    (maybe False (maybe False urlPrimary . listToMaybe . detailUrls) d2)

  TIO.putStrLn "5. delete"
  del <- removeResource conn rid
  check "delete succeeds" (isRight del)
  d3 <- getResourceDetails conn rid
  check "resource is gone" (isNothing d3)

  TIO.putStrLn "6. transaction rollback (author 999999 does not exist)"
  rb <- createResource conn draft
    { draftName = "Smoke rollback", draftAuthorIds = [999999] }
  check "FK failure returns Left" (isLeft rb)
  rs <- findAll @Resource conn
  check "no half-created row"
    (all (not . T.isPrefixOf "Smoke rollback" . resName) rs)

check :: String -> Bool -> IO ()
check label ok = do
  TIO.putStrLn ((if ok then "[PASS] " else "[FAIL] ") <> T.pack label)
  unless ok (ioError (userError ("check failed: " <> label)))

isLeft :: Either a b -> Bool
isLeft (Left _)  = True
isLeft (Right _) = False

isRight :: Either a b -> Bool
isRight = not . isLeft

draft :: ResourceDraft
draft = ResourceDraft
  { draftName        = "Smoke resource"
  , draftAnnotation  = "Smoke annotation"
  , draftKindId      = 9001
  , draftPurposeId   = 9002
  , draftConditionId = 9003
  , draftOpenedOn    = fromGregorian 2024 9 1
  , draftTermText    = "1 year"
  , draftValidUntil  = Nothing
  , draftAuthorIds   = [9101, 9102]
  , draftUrls        =
      [ ResourceUrlDraft "https://example.org/a" (Just "main") True
      , ResourceUrlDraft "https://example.org/b" Nothing False
      ]
  }

setup :: MySQLConn -> IO ()
setup conn = do
  execute_ conn "INSERT INTO kinds (id, name) VALUES (9001, 'Smoke kind')"
  execute_ conn "INSERT INTO purposes (id, name) VALUES (9002, 'Smoke purpose')"
  execute_ conn "INSERT INTO usage_conditions (id, name) VALUES (9003, 'Smoke condition')"
  execute_ conn "INSERT INTO authors (id, full_name, email, affiliation) VALUES (9101, 'Smoke Author One', 'one@example.org', 'Dept')"
  execute_ conn "INSERT INTO authors (id, full_name, email, affiliation) VALUES (9102, 'Smoke Author Two', NULL, NULL)"
  pure ()

cleanup :: MySQLConn -> IO ()
cleanup conn = do
  execute_ conn "DELETE FROM resources WHERE name LIKE 'Smoke%'"
  execute_ conn "DELETE FROM authors WHERE id IN (9101, 9102)"
  execute_ conn "DELETE FROM kinds WHERE id = 9001"
  execute_ conn "DELETE FROM purposes WHERE id = 9002"
  execute_ conn "DELETE FROM usage_conditions WHERE id = 9003"
  pure ()
