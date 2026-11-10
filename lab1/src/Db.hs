{-# LANGUAGE OverloadedStrings #-}

-- | Connection settings and a bracket-based helper for opening MySQL.
module Db
  ( DbConfig (..)
  , defaultConfig
  , withConnection
  ) where

import Control.Exception (bracket)
import Data.ByteString (ByteString)
import Database.MySQL.Base

-- | Everything needed to open a connection.
-- Keep credentials here for now; later they can come from env vars or CLI.
data DbConfig = DbConfig
  { dbHost     :: String
  , dbPort     :: Int
  , dbName     :: ByteString
  , dbUser     :: ByteString
  , dbPassword :: ByteString
  }

-- | Matches the docker command in README.md.
defaultConfig :: DbConfig
defaultConfig = DbConfig
  { dbHost     = "127.0.0.1"
  , dbPort     = 3306
  , dbName     = "dept_resources"
  , dbUser     = "root"
  , dbPassword = "root"
  }

toConnectInfo :: DbConfig -> ConnectInfo
toConnectInfo cfg = defaultConnectInfoMB4
  { ciHost     = dbHost cfg
  , ciPort     = fromIntegral (dbPort cfg)
  , ciDatabase = dbName cfg
  , ciUser     = dbUser cfg
  , ciPassword = dbPassword cfg
  }

-- | Opens a connection, runs the action, closes the connection even on error.
withConnection :: DbConfig -> (MySQLConn -> IO a) -> IO a
withConnection cfg action =
  bracket (connect (toConnectInfo cfg)) close action
