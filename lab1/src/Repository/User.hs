{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Repository.User
  ( insertUser
  , updateUser
  , findUserByEmail
  ) where

import Control.Monad (void)
import Data.Maybe (listToMaybe)
import Data.Text (Text)
import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn, MySQLValue (..), OK (..), Query, execute)
import Model.User (User (..), UserDraft (..), roleFromText, roleToText)
import Repository.Class
  ( FromRow (..)
  , Repository (..)
  , maybeText
  , selectRows
  )

instance FromRow User where
  fromRow [ MySQLInt32U i, MySQLText n, MySQLText e, MySQLText r, d ] =
    User i n e <$> roleFromText r <*> maybeText d
  fromRow r = Left ("User: unexpected row shape: " <> show r)

instance Repository User where
  tableName  _ = "users"
  columnList _ = [ "id", "full_name", "email", "role", "department" ]
  primaryKey _ = "id"

findUserByEmail :: MySQLConn -> Text -> IO (Maybe User)
findUserByEmail conn email = do
  rs <- selectRows conn
    "SELECT id, full_name, email, role, department \
    \FROM users WHERE email = ? LIMIT 1"
    [MySQLText email]
  pure (listToMaybe rs)

insertUser :: MySQLConn -> UserDraft -> IO Word32
insertUser conn d = do
  ok <- execute conn insertSql (userParams d)
  pure (fromIntegral (okLastInsertID ok))

updateUser :: MySQLConn -> Word32 -> UserDraft -> IO ()
updateUser conn uid d =
  void $ execute conn updateSql (userParams d ++ [MySQLInt32U uid])

insertSql :: Query
insertSql = "INSERT INTO users (full_name, email, role, department) VALUES (?, ?, ?, ?)"

updateSql :: Query
updateSql = "UPDATE users SET full_name = ?, email = ?, role = ?, department = ? WHERE id = ?"

userParams :: UserDraft -> [MySQLValue]
userParams d =
  [ MySQLText (userDraftName d)
  , MySQLText (userDraftEmail d)
  , MySQLText (roleToText (userDraftRole d))
  , maybe MySQLNull MySQLText (userDraftDepartment d)
  ]
