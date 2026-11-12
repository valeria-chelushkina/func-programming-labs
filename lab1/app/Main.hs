{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Exception (SomeException, displayException, try)
import qualified Data.Text.IO as T
import Database.MySQL.Base (MySQLConn, MySQLValue (..), query_)
import System.IO (hSetEncoding, stdin, stdout, utf8)
import qualified System.IO.Streams as Streams

import Db.Config (defaultConfig)
import Db.Connection (withConnection)
import Repository.Class (Repository (..))
import Repository.Resource ()
import Ui.Render (printResource)

main :: IO ()
main = do
  -- Windows console is not UTF-8 by default; this keeps Ukrainian text readable.
  hSetEncoding stdout utf8
  hSetEncoding stdin utf8

  result <- try (withConnection defaultConfig run)
    :: IO (Either SomeException ())
  case result of
    Left err -> putStrLn ("Error: " <> displayException err)
    Right () -> pure ()

run :: MySQLConn -> IO ()
run conn = do
  checkConnection conn
  putStrLn ""
  putStrLn "Resources:"
  rs <- findAll conn
  if null rs
    then putStrLn "  (empty - the resources table has no rows)"
    else mapM_ printResource rs

-- | Smoke test: proves that the driver and the database are reachable.
checkConnection :: MySQLConn -> IO ()
checkConnection conn = do
  (_, rows) <- query_ conn "SELECT VERSION()"
  rs <- Streams.toList rows
  case rs of
    ([MySQLText v] : _) -> T.putStrLn ("Connected to MySQL " <> v)
    _                   -> putStrLn "Connected, but VERSION() returned no rows."
