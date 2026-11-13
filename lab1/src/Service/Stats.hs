{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Service.Stats
  ( recordUsage
  , resourceUsage
  , topResources
  , userUsageCount
  ) where

import Control.Exception (SomeException, displayException, try)
import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn)

import Model.Resource (Resource)
import Model.Stats (ResourceUsage, TopResource, UsageRecord (..))
import Model.User (User)
import Repository.Class (Repository (..))
import qualified Repository.Stats as Repo
import Repository.Resource ()
import Repository.User ()

recordUsage :: MySQLConn -> UsageRecord -> IO (Either String ())
recordUsage conn u
  | usageMinutes u < 0 =
      pure (Left "minutes must not be negative")
  | usageMinutes u > 1440 =
      pure (Left "minutes must be between 0 and 1440")
  | otherwise = do
      muser <- findById @User conn (usageUserId u)
      mres  <- findById @Resource conn (usageResourceId u)
      case (muser, mres) of
        (Nothing, _) ->
          pure (Left ("user " <> show (usageUserId u) <> " not found"))
        (_, Nothing) ->
          pure (Left ("resource " <> show (usageResourceId u) <> " not found"))
        _ -> do
          r <- try (Repo.insertUsage conn u) :: IO (Either SomeException ())
          pure (either (Left . displayException) Right r)

resourceUsage :: MySQLConn -> Word32 -> IO ResourceUsage
resourceUsage = Repo.resourceUsage

topResources :: MySQLConn -> Int -> IO [TopResource]
topResources conn n = Repo.topResources conn (max 1 (min 100 n))

userUsageCount :: MySQLConn -> Word32 -> IO Int
userUsageCount = Repo.userUsageCount
