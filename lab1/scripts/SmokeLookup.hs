{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | Manual smoke test for dictionary listings.
--
-- Run from lab1/:
--   cabal exec -- runghc -isrc scripts\SmokeLookup.hs
module Main where

import Control.Exception (finally)
import Control.Monad (unless)
import Data.Maybe (isJust, isNothing)
import Database.MySQL.Base (MySQLConn, execute_)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

import Db.Config (defaultConfig)
import Db.Connection (withConnection)
import Model.Lookup (Kind (..), Purpose (..), UsageCondition (..))
import Service.Lookup

main :: IO ()
main = withConnection defaultConfig $ \conn ->
  (do cleanup conn
      setup conn
      checks conn
      TIO.putStrLn ""
      TIO.putStrLn "ALL LOOKUP CHECKS PASSED")
    `finally` cleanup conn

checks :: MySQLConn -> IO ()
checks conn = do
  TIO.putStrLn "1. kinds"
  kinds <- listKinds conn
  check "kind appears in list" (any ((== 9301) . kindId) kinds)
  check "kind name is correct"
    (any ((== "Smoke kind") . kindName) kinds)
  mk <- getKind conn 9301
  check "getKind returns the row"
    (maybe False ((== "Smoke kind") . kindName) mk)

  TIO.putStrLn "2. purposes"
  purposes <- listPurposes conn
  check "purpose appears in list" (any ((== 9302) . purposeId) purposes)
  mp <- getPurpose conn 9302
  check "getPurpose returns the row"
    (maybe False ((== "Smoke purpose") . purposeName) mp)

  TIO.putStrLn "3. usage conditions"
  conditions <- listConditions conn
  check "condition appears in list"
    (any ((== 9303) . conditionId) conditions)
  mc <- getCondition conn 9303
  check "description is loaded"
    (maybe False ((== Just "Smoke description") . conditionDescription) mc)

  TIO.putStrLn "4. missing kind"
  mk2 <- getKind conn 999999
  check "getKind 999999 is Nothing" (isNothing mk2)
  check "existing kind is Just" (isJust mk)

check :: String -> Bool -> IO ()
check label ok = do
  TIO.putStrLn ((if ok then "[PASS] " else "[FAIL] ") <> T.pack label)
  unless ok (ioError (userError ("check failed: " <> label)))

setup :: MySQLConn -> IO ()
setup conn = do
  execute_ conn "INSERT INTO kinds (id, name) VALUES (9301, 'Smoke kind')"
  execute_ conn "INSERT INTO purposes (id, name) VALUES (9302, 'Smoke purpose')"
  execute_ conn "INSERT INTO usage_conditions (id, name, description) VALUES (9303, 'Smoke condition', 'Smoke description')"
  pure ()

cleanup :: MySQLConn -> IO ()
cleanup conn = do
  execute_ conn "DELETE FROM kinds WHERE id = 9301"
  execute_ conn "DELETE FROM purposes WHERE id = 9302"
  execute_ conn "DELETE FROM usage_conditions WHERE id = 9303"
  pure ()
