{-# LANGUAGE OverloadedStrings #-}

module Web.Pages.Authors
  ( authorsPage
  , authorFormPage
  ) where

import Data.Text (Text)
import Lucid

import Model.Author (Author (..))
import Web.Components (alert, pageHead, showId)
import Web.Forms (AuthorForm (..))

authorsPage :: [Author] -> Html ()
authorsPage authors = do
  div_ [class_ "page-head-row"] $ do
    pageHead "Authors" "People who create the resources"
    a_ [href_ "/authors/new", class_ "btn btn-primary"] "Add author"
  table_ [class_ "table"] $ do
    thead_ $ tr_ $ do
      th_ "ID"
      th_ "Name"
      th_ "Email"
      th_ "Affiliation"
      th_ [class_ "actions-col"] "Actions"
    tbody_ $ mapM_ row authors
  where
    row :: Author -> Html ()
    row a = tr_ $ do
      td_ [class_ "muted"] (toHtml (showId (authorId a)))
      td_ (toHtml (authorName a))
      td_ (toHtml (maybe "—" id (authorEmail a)))
      td_ (toHtml (maybe "—" id (authorAffiliation a)))
      td_ [class_ "actions-col"] $
        a_ [href_ ("/authors/" <> showId (authorId a) <> "/edit"), class_ "btn btn-sm btn-ghost"] "Edit"

authorFormPage :: Text -> Maybe Text -> AuthorForm -> Html ()
authorFormPage action merr f = do
  pageHead "Author" "Create or update an author"
  maybe (pure ()) alert merr
  form_ [method_ "post", action_ action, class_ "form"] $ do
    label_ [class_ "field"] $ do
      span_ "Full name *"
      input_ [type_ "text", name_ "name", value_ (formAuthorName f), class_ "input", required_ ""]
    label_ [class_ "field"] $ do
      span_ "Email"
      input_ [type_ "email", name_ "email", value_ (formAuthorEmail f), class_ "input"]
    label_ [class_ "field"] $ do
      span_ "Affiliation"
      input_ [type_ "text", name_ "affiliation", value_ (formAuthorAffiliation f), class_ "input"]
    div_ [class_ "actions"] $ do
      button_ [type_ "submit", class_ "btn btn-primary"] "Save"
      a_ [href_ "/authors", class_ "btn btn-ghost"] "Cancel"
