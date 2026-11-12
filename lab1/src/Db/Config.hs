{-# LANGUAGE OverloadedStrings #-}

-- | Database connection settings.
module Db.Config
  ( DbConfig (..)
  , defaultConfig
  , toConnectInfo
  ) where

import Data.ByteString (ByteString)
import Database.MySQL.Base (ConnectInfo (..), defaultConnectInfoMB4)

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
