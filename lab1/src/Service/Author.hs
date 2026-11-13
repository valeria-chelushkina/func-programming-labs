{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Service.Author
  ( createAuthor
  , editAuthor
  , listAuthors
  , getAuthor
  ) where

import Control.Exception (SomeException, displayException, try)
import qualified Data.Text as T
import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn)
import Model.Author (Author, AuthorDraft (..))
import Repository.Author (insertAuthor, updateAuthor)
import Repository.Class (Repository (..))

createAuthor :: MySQLConn -> AuthorDraft -> IO (Either String Word32)
createAuthor conn d =
  case validateDraft d of
    Left err -> pure (Left err)
    Right () -> do
      r <- try (insertAuthor conn (normalizeDraft d))
        :: IO (Either SomeException Word32)
      pure (either (Left . displayException) Right r)

editAuthor :: MySQLConn -> Word32 -> AuthorDraft -> IO (Either String ())
editAuthor conn aid d =
  case validateDraft d of
    Left err -> pure (Left err)
    Right () -> do
      existing <- findById @Author conn aid
      case existing of
        Nothing -> pure (Left ("author " <> show aid <> " not found"))
        Just _ -> do
          r <- try (updateAuthor conn aid (normalizeDraft d))
            :: IO (Either SomeException ())
          pure (either (Left . displayException) Right r)

listAuthors :: MySQLConn -> IO [Author]
listAuthors conn = findAll @Author conn

getAuthor :: MySQLConn -> Word32 -> IO (Maybe Author)
getAuthor conn aid = findById @Author conn aid

validateDraft :: AuthorDraft -> Either String ()
validateDraft d
  | T.null (T.strip (authorDraftName d)) =
      Left "author name must not be empty"
  | T.length (authorDraftName d) > 150 =
      Left "author name is too long (max 150 characters)"
  | maybe False ((> 150) . T.length) (authorDraftEmail d) =
      Left "email is too long (max 150 characters)"
  | maybe False (notElem '@' . T.unpack) (authorDraftEmail d) =
      Left "email must contain @"
  | maybe False ((> 150) . T.length) (authorDraftAffiliation d) =
      Left "affiliation is too long (max 150 characters)"
  | otherwise =
      Right ()

normalizeDraft :: AuthorDraft -> AuthorDraft
normalizeDraft d = d
  { authorDraftName        = T.strip (authorDraftName d)
  , authorDraftEmail       = cleanText (authorDraftEmail d)
  , authorDraftAffiliation = cleanText (authorDraftAffiliation d)
  }

cleanText :: Maybe T.Text -> Maybe T.Text
cleanText Nothing  = Nothing
cleanText (Just t) =
  let s = T.strip t
   in if T.null s then Nothing else Just s
