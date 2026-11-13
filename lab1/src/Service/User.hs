{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Service.User
  ( createUser
  , editUser
  , listUsers
  , getUser
  ) where

import Control.Exception (SomeException, displayException, try)
import qualified Data.Text as T
import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn)
import Model.User (User (..), UserDraft (..))
import Repository.Class (Repository (..))
import Repository.User (findUserByEmail, insertUser, updateUser)

createUser :: MySQLConn -> UserDraft -> IO (Either String Word32)
createUser conn d =
  case validateDraft d of
    Left err -> pure (Left err)
    Right () -> do
      let d' = normalizeDraft d
      existing <- findUserByEmail conn (userDraftEmail d')
      case existing of
        Just _  -> pure (Left "email is already used")
        Nothing -> do
          r <- try (insertUser conn d') :: IO (Either SomeException Word32)
          pure (either (Left . displayException) Right r)

editUser :: MySQLConn -> Word32 -> UserDraft -> IO (Either String ())
editUser conn uid d =
  case validateDraft d of
    Left err -> pure (Left err)
    Right () -> do
      existing <- findById @User conn uid
      case existing of
        Nothing -> pure (Left ("user " <> show uid <> " not found"))
        Just _ -> do
          let d' = normalizeDraft d
          other <- findUserByEmail conn (userDraftEmail d')
          case other of
            Just u | userId u /= uid ->
              pure (Left "email is already used by another user")
            _ -> do
              r <- try (updateUser conn uid d') :: IO (Either SomeException ())
              pure (either (Left . displayException) Right r)

listUsers :: MySQLConn -> IO [User]
listUsers conn = findAll @User conn

getUser :: MySQLConn -> Word32 -> IO (Maybe User)
getUser conn uid = findById @User conn uid

validateDraft :: UserDraft -> Either String ()
validateDraft d
  | T.null (T.strip (userDraftName d)) =
      Left "user name must not be empty"
  | T.length (userDraftName d) > 150 =
      Left "user name is too long (max 150 characters)"
  | T.null (T.strip (userDraftEmail d)) =
      Left "email must not be empty"
  | T.length (userDraftEmail d) > 150 =
      Left "email is too long (max 150 characters)"
  | notElem '@' (T.unpack (userDraftEmail d)) =
      Left "email must contain @"
  | maybe False ((> 150) . T.length) (userDraftDepartment d) =
      Left "department is too long (max 150 characters)"
  | otherwise =
      Right ()

normalizeDraft :: UserDraft -> UserDraft
normalizeDraft d = d
  { userDraftName       = T.strip (userDraftName d)
  , userDraftEmail      = T.strip (userDraftEmail d)
  , userDraftDepartment = cleanText (userDraftDepartment d)
  }

cleanText :: Maybe T.Text -> Maybe T.Text
cleanText Nothing  = Nothing
cleanText (Just t) =
  let s = T.strip t
   in if T.null s then Nothing else Just s
