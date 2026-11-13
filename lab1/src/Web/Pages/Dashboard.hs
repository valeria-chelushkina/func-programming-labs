{-# LANGUAGE OverloadedStrings #-}

module Web.Pages.Dashboard
  ( dashboardPage
  ) where

import Data.Text (Text)
import Lucid
import Model.Stats (TopResource (..))
import Web.Components (card, emptyState, pageHead, panel)

dashboardPage :: [(Text, Text)] -> [TopResource] -> Html ()
dashboardPage cards top = do
  pageHead "Dashboard" "Information resources of the department"
  div_ [class_ "cards"] $ mapM_ card cards
  panel "Top resources" $
    if null top
      then emptyState "No usage recorded yet."
      else table_ [class_ "table"] $ do
        thead_ $ tr_ $ do
          th_ "Resource"
          th_ [class_ "num"] "Uses"
        tbody_ $ mapM_ (\t -> tr_ $ do
          td_ (toHtml (trName t))
          td_ [class_ "num"] (toHtml (show (trUses t)))) top
  panel "Quick actions" $
    div_ [class_ "actions"] $ do
      a_ [href_ "/resources/new", class_ "btn btn-primary"] "Add resource"
      a_ [href_ "/authors/new", class_ "btn btn-ghost"] "Add author"
      a_ [href_ "/users/new", class_ "btn btn-ghost"] "Add user"
