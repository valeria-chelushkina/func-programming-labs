{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Manual smoke test for author CRUD.
--
-- Run from lab1/:
--   cabal exec -- runghc -isrc scripts\SmokeAuthor.hs
module Main where

import Control.Exception (finally)
import Control.Monad (unless)
import Data.Maybe (isJust, isNothing)
import Database.MySQL.Base (MySQLConn, execute_)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

import Db.Config (defaultConfig)
import Db.Connection (withConnection)
import Model.Author (Author (..), AuthorDraft (..))
import Service.Author

main :: IO ()
main = withConnection defaultConfig $ \conn ->
  (do cleanup conn
      checks conn
      TIO.putStrLn ""
      TIO.putStrLn "ALL AUTHOR CHECKS PASSED")
    `finally` cleanup conn

checks :: MySQLConn -> IO ()
checks conn = do
  TIO.putStrLn "1. validation: empty name"
  r1 <- createAuthor conn draft { authorDraftName = "   " }
  check "rejects empty name" (isLeft r1)

  TIO.putStrLn "2. validation: invalid email"
  r2 <- createAuthor conn draft { authorDraftEmail = Just "not-an-email" }
  check "rejects invalid email" (isLeft r2)

  TIO.putStrLn "3. create"
  created <- createAuthor conn draft
  aid <- case created of
    Left err -> ioError (userError ("create failed: " <> err))
    Right i  -> pure i
  check "create returns an id" (aid > 0)

  TIO.putStrLn "4. read"
  m1 <- getAuthor conn aid
  check "author exists" (isJust m1)
  check "name matches"
    (maybe False ((== "Smoke Author One") . authorName) m1)
  check "blank affiliation normalised to NULL"
    (maybe False (isNothing . authorAffiliation) m1)

  TIO.putStrLn "5. list"
  authors <- listAuthors conn
  check "author appears in list" (any ((== aid) . authorId) authors)

  TIO.putStrLn "6. edit"
  upd <- editAuthor conn aid draft
    { authorDraftName  = "Smoke Author Edited"
    , authorDraftEmail = Just "new@example.org"
    }
  check "edit succeeds" (isRight upd)

  m2 <- getAuthor conn aid
  check "name updated"
    (maybe False ((== "Smoke Author Edited") . authorName) m2)
  check "email updated"
    (maybe False ((== Just "new@example.org") . authorEmail) m2)

  TIO.putStrLn "7. edit a missing author"
  missing <- editAuthor conn 999999 draft
  check "missing author returns Left" (isLeft missing)

check :: String -> Bool -> IO ()
check label ok = do
  TIO.putStrLn ((if ok then "[PASS] " else "[FAIL] ") <> T.pack label)
  unless ok (ioError (userError ("check failed: " <> label)))

isLeft :: Either a b -> Bool
isLeft (Left _)  = True
isLeft (Right _) = False

isRight :: Either a b -> Bool
isRight = not . isLeft

draft :: AuthorDraft
draft = AuthorDraft
  { authorDraftName        = "Smoke Author One"
  , authorDraftEmail       = Just "one@example.org"
  , authorDraftAffiliation = Just "   "
  }

cleanup :: MySQLConn -> IO ()
cleanup conn = do
  execute_ conn "DELETE FROM authors WHERE full_name LIKE 'Smoke Author%'"
  pure ()
