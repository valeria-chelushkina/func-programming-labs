-- | Opening connections and running transactions.
module Db.Connection
  ( withConnection
  , withTransaction
  ) where

import Control.Exception (bracket)
import Database.MySQL.Base (MySQLConn, close, connect, withTransaction)
import Db.Config (DbConfig, toConnectInfo)

-- | Opens a connection, runs the action, closes it even on error.
withConnection :: DbConfig -> (MySQLConn -> IO a) -> IO a
withConnection cfg action =
  bracket (connect (toConnectInfo cfg)) close action
