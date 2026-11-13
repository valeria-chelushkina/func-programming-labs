{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Repository.Search
  ( findByFilter
  ) where

import Data.Maybe (catMaybes)
import Data.Proxy (Proxy (..))
import Data.Text (Text)
import qualified Data.Text as T
import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn, MySQLValue (..))
import Model.Filters (ResourceFilter (..))
import Model.Resource (Resource)
import Repository.Class (Repository (..), selectAllSql, selectRows)
import Repository.Resource ()

findByFilter :: MySQLConn -> ResourceFilter -> IO [Resource]
findByFilter conn f =
  selectRows conn sql params
  where
    (clauses, params) = buildWhere f

    sql = selectAllSql
            (tableName (Proxy :: Proxy Resource))
            (columnList (Proxy :: Proxy Resource))
          <> wherePart clauses
          <> " ORDER BY name"

wherePart :: [Text] -> Text
wherePart [] = ""
wherePart cs = " WHERE " <> T.intercalate " AND " cs

buildWhere :: ResourceFilter -> ([Text], [MySQLValue])
buildWhere f =
  let parts = catMaybes
        [ textPart (T.strip (rfText f))
        , kindPart (rfKindId f)
        , purposePart (rfPurposeId f)
        , authorPart (rfAuthorId f)
        ]
   in (map fst parts, concatMap snd parts)

textPart :: Text -> Maybe (Text, [MySQLValue])
textPart t
  | T.null t = Nothing
  | otherwise = Just
      ( "(name LIKE CONCAT('%', ?, '%') OR annotation LIKE CONCAT('%', ?, '%'))"
      , [MySQLText t, MySQLText t]
      )

kindPart :: Maybe Word32 -> Maybe (Text, [MySQLValue])
kindPart Nothing  = Nothing
kindPart (Just k) = Just ("kind_id = ?", [MySQLInt32U k])

purposePart :: Maybe Word32 -> Maybe (Text, [MySQLValue])
purposePart Nothing  = Nothing
purposePart (Just p) = Just ("purpose_id = ?", [MySQLInt32U p])

authorPart :: Maybe Word32 -> Maybe (Text, [MySQLValue])
authorPart Nothing  = Nothing
authorPart (Just a) = Just
  ( "EXISTS (SELECT 1 FROM resource_authors ra \
    \WHERE ra.resource_id = resources.id AND ra.author_id = ?)"
  , [MySQLInt32U a]
  )
