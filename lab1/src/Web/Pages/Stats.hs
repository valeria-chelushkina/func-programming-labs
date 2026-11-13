{-# LANGUAGE OverloadedStrings #-}

module Web.Pages.Stats
  ( statsPage
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Lucid

import Model.Resource (Resource (..))
import Model.Stats (ResourceUsage (..))
import Model.User (User (..))
import Web.Components (card, pageHead, panel)

statsPage :: Int -> [(Resource, ResourceUsage)] -> [(User, Int)] -> Html ()
statsPage total rows userRows = do
  pageHead "Statistics" "Usage of the department resources"
  div_ [class_ "cards"] $ do
    card ("Total records", T.pack (show total))
    card ("Resources tracked", T.pack (show (length rows)))
    card ("Users tracked", T.pack (show (length userRows)))
  div_ [class_ "grid-2"] $ do
    panel "Per resource" $
      table_ [class_ "table"] $ do
        thead_ $ tr_ $ do
          th_ "Resource"
          th_ [class_ "num"] "Uses"
          th_ [class_ "num"] "Users"
        tbody_ $ mapM_ (\(r, u) -> tr_ $ do
          td_ (toHtml (resName r))
          td_ [class_ "num"] (toHtml (show (ruUses u)))
          td_ [class_ "num"] (toHtml (show (ruUniqueUsers u)))) rows
    panel "Per user" $
      table_ [class_ "table"] $ do
        thead_ $ tr_ $ do
          th_ "User"
          th_ [class_ "num"] "Records"
        tbody_ $ mapM_ (\(u, n) -> tr_ $ do
          td_ (toHtml (userName u))
          td_ [class_ "num"] (toHtml (show n))) userRows
