{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Service.Resource
  ( createResource
  , editResource
  , removeResource
  , getResourceDetails
  , listResourceDetails
  , searchResources
  , searchResourceDetails
  ) where

import Control.Exception (SomeException, displayException, try)
import qualified Data.Text as T
import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn)
import Model.Filters (ResourceFilter (..))
import Model.Resource (Resource (..), ResourceDetails (..), ResourceDraft (..))
import Model.ResourceUrl (ResourceUrlDraft (..))
import Repository.Author (findAuthorsByResource)
import Repository.Class (Repository (..))
import Repository.Resource (insertResource, updateResource)
import Repository.ResourceUrl (findUrlsByResource)
import Repository.Search (findByFilter)

createResource :: MySQLConn -> ResourceDraft -> IO (Either String Word32)
createResource conn d =
  case validateDraft d of
    Left err -> pure (Left err)
    Right () -> do
      r <- try (insertResource conn (normalizeDraft d))
        :: IO (Either SomeException Word32)
      pure (either (Left . displayException) Right r)

editResource :: MySQLConn -> Word32 -> ResourceDraft -> IO (Either String ())
editResource conn rid d =
  case validateDraft d of
    Left err -> pure (Left err)
    Right () -> do
      existing <- findById @Resource conn rid
      case existing of
        Nothing -> pure (Left ("resource " <> show rid <> " not found"))
        Just _ -> do
          r <- try (updateResource conn rid (normalizeDraft d))
            :: IO (Either SomeException ())
          pure (either (Left . displayException) Right r)

removeResource :: MySQLConn -> Word32 -> IO (Either String ())
removeResource conn rid = do
  existing <- findById @Resource conn rid
  case existing of
    Nothing -> pure (Left ("resource " <> show rid <> " not found"))
    Just _ -> do
      r <- try (deleteById @Resource conn rid)
        :: IO (Either SomeException ())
      pure (either (Left . displayException) Right r)

getResourceDetails :: MySQLConn -> Word32 -> IO (Maybe ResourceDetails)
getResourceDetails conn rid = do
  mr <- findById @Resource conn rid
  case mr of
    Nothing -> pure Nothing
    Just r  -> Just <$> detailsFor conn r

listResourceDetails :: MySQLConn -> IO [ResourceDetails]
listResourceDetails conn = do
  rs <- findAll @Resource conn
  mapM (detailsFor conn) rs

searchResources :: MySQLConn -> ResourceFilter -> IO [Resource]
searchResources conn f =
  let f' = f { rfText = T.strip (rfText f) }
   in findByFilter conn f'

searchResourceDetails :: MySQLConn -> ResourceFilter -> IO [ResourceDetails]
searchResourceDetails conn f = do
  rs <- searchResources conn f
  mapM (detailsFor conn) rs

detailsFor :: MySQLConn -> Resource -> IO ResourceDetails
detailsFor conn r = do
  authors <- findAuthorsByResource conn (resId r)
  urls    <- findUrlsByResource conn (resId r)
  pure (ResourceDetails r authors urls)

validateDraft :: ResourceDraft -> Either String ()
validateDraft d
  | T.null (T.strip (draftName d)) =
      Left "name must not be empty"
  | T.length (draftName d) > 255 =
      Left "name is too long (max 255 characters)"
  | T.null (T.strip (draftTermText d)) =
      Left "term must not be empty"
  | null (draftAuthorIds d) =
      Left "at least one author is required"
  | null (draftUrls d) =
      Left "at least one URL is required"
  | any (T.null . T.strip . urlDraftAddress) (draftUrls d) =
      Left "URL must not be empty"
  | length (filter urlDraftPrimary (draftUrls d)) > 1 =
      Left "at most one primary URL is allowed"
  | otherwise =
      Right ()

-- | If the user marked no URL as primary, promote the first one.
normalizeDraft :: ResourceDraft -> ResourceDraft
normalizeDraft d
  | any urlDraftPrimary (draftUrls d) = d
  | otherwise =
      case draftUrls d of
        []       -> d
        (u : us) -> d { draftUrls = u { urlDraftPrimary = True } : us }
