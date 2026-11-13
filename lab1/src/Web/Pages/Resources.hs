{-# LANGUAGE OverloadedStrings #-}

module Web.Pages.Resources
  ( resourcesPage
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Lucid

import Model.Author (Author (..))
import Model.Lookup (Kind (..), Purpose (..))
import Model.Resource (Resource (..), ResourceDetails (..))
import Web.Components (emptyState, pageHead, panel, showId)
import Web.Forms (ResourceView (..))

resourcesPage :: Text -> [Kind] -> [Purpose] -> [ResourceView] -> Html ()
resourcesPage q kinds purposes rows = do
  div_ [class_ "page-head-row"] $ do
    pageHead "Resources" "Search, inspect and manage the catalogue"
    a_ [href_ "/resources/new", class_ "btn btn-primary"] "Add resource"
  form_ [method_ "get", action_ "/resources", class_ "filters"] $ do
    input_ [type_ "search", name_ "q", value_ q, placeholder_ "Search name or annotation…"]
    select_ [name_ "kind"] $ do
      option_ [value_ ""] "All kinds"
      mapM_ (\k -> option_ [value_ (showId (kindId k))] (toHtml (kindName k))) kinds
    select_ [name_ "purpose"] $ do
      option_ [value_ ""] "All purposes"
      mapM_ (\p -> option_ [value_ (showId (purposeId p))] (toHtml (purposeName p))) purposes
    button_ [type_ "submit", class_ "btn btn-primary"] "Search"
    a_ [href_ "/resources", class_ "btn btn-ghost"] "Reset"
  if null rows
    then panel "No results" (emptyState "Nothing matches this filter.")
    else table_ [class_ "table"] $ do
      thead_ $ tr_ $ do
        th_ "ID"
        th_ "Name"
        th_ "Kind"
        th_ "Authors"
        th_ "URLs"
        th_ [class_ "actions-col"] "Actions"
      tbody_ $ mapM_ row rows
  where
    row :: ResourceView -> Html ()
    row rv =
      let d = rvDetails rv
          r = detailResource d
          authors = T.intercalate ", " (map authorName (detailAuthors d))
       in tr_ $ do
            td_ [class_ "muted"] (toHtml (showId (resId r)))
            td_ $ a_ [href_ ("/resources/" <> showId (resId r))] (toHtml (resName r))
            td_ $ span_ [class_ "badge"] (toHtml (rvKind rv))
            td_ (toHtml (if T.null authors then "—" else authors))
            td_ [class_ "num"] (toHtml (show (length (detailUrls d))))
            td_ [class_ "actions-col"] $ do
              a_ [href_ ("/resources/" <> showId (resId r)), class_ "btn btn-sm"] "View"
              a_ [href_ ("/resources/" <> showId (resId r) <> "/edit"), class_ "btn btn-sm btn-ghost"] "Edit"
