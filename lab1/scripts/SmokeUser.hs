{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Manual smoke test for user management.
--
-- Run from lab1/:
--   cabal exec -- runghc -isrc scripts\SmokeUser.hs
module Main where

import Control.Exception (finally)
import Control.Monad (unless)
import Data.Maybe (isJust, isNothing)
import Database.MySQL.Base (MySQLConn, execute_)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

import Db.Config (defaultConfig)
import Db.Connection (withConnection)
import Model.User (Role (..), User (..), UserDraft (..))
import Service.User

main :: IO ()
main = withConnection defaultConfig $ \conn ->
  (do cleanup conn
      checks conn
      TIO.putStrLn ""
      TIO.putStrLn "ALL USER CHECKS PASSED")
    `finally` cleanup conn

checks :: MySQLConn -> IO ()
checks conn = do
  TIO.putStrLn "1. validation"
  r1 <- createUser conn draft { userDraftName = "   " }
  check "rejects empty name" (isLeft r1)
  r2 <- createUser conn draft { userDraftEmail = "not-an-email" }
  check "rejects invalid email" (isLeft r2)

  TIO.putStrLn "2. create"
  created <- createUser conn draft
  uid <- case created of
    Left err -> ioError (userError ("create failed: " <> err))
    Right i  -> pure i
  check "create returns an id" (uid > 0)

  TIO.putStrLn "3. read"
  mu <- getUser conn uid
  check "user exists" (isJust mu)
  check "name matches" (maybe False ((== "Smoke User One") . userName) mu)
  check "role is Student" (maybe False ((== Student) . userRole) mu)
  check "department normalised"
    (maybe False ((== Just "Dept") . userDepartment) mu)

  TIO.putStrLn "4. list"
  users <- listUsers conn
  check "user appears in list" (any ((== uid) . userId) users)

  TIO.putStrLn "5. duplicate email"
  dup <- createUser conn draft { userDraftName = "Smoke User Dup" }
  check "duplicate email is rejected" (isLeft dup)

  TIO.putStrLn "6. edit"
  upd <- editUser conn uid draft
    { userDraftName       = "Smoke User Edited"
    , userDraftRole       = Teacher
    , userDraftDepartment = Just "   "
    }
  check "edit succeeds" (isRight upd)

  mu2 <- getUser conn uid
  check "name updated"
    (maybe False ((== "Smoke User Edited") . userName) mu2)
  check "role updated"
    (maybe False ((== Teacher) . userRole) mu2)
  check "blank department becomes NULL"
    (maybe False (isNothing . userDepartment) mu2)

  TIO.putStrLn "7. edit a missing user"
  missing <- editUser conn 999999 draft
  check "missing user returns Left" (isLeft missing)

check :: String -> Bool -> IO ()
check label ok = do
  TIO.putStrLn ((if ok then "[PASS] " else "[FAIL] ") <> T.pack label)
  unless ok (ioError (userError ("check failed: " <> label)))

isLeft :: Either a b -> Bool
isLeft (Left _)  = True
isLeft (Right _) = False

isRight :: Either a b -> Bool
isRight = not . isLeft

draft :: UserDraft
draft = UserDraft
  { userDraftName       = "Smoke User One"
  , userDraftEmail      = "smoke.user.one@example.org"
  , userDraftRole       = Student
  , userDraftDepartment = Just "Dept"
  }

cleanup :: MySQLConn -> IO ()
cleanup conn = do
  execute_ conn "DELETE FROM users WHERE email LIKE 'smoke.user.%'"
  pure ()
