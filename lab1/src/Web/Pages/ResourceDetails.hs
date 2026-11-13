{-# LANGUAGE OverloadedStrings #-}

module Web.Pages.ResourceDetails
  ( resourceDetailsPage
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Lucid

import Model.Author (Author (..))
import Model.Resource (Resource (..), ResourceDetails (..))
import Model.ResourceUrl (ResourceUrl (..))
import Model.Stats (ResourceUsage (..))
import Model.User (User (..))
import Web.Components
  ( card
  , emptyState
  , formatDateTime
  , formatDay
  , pageHead
  , panel
  , showId
  )
import Web.Forms (ResourceView (..))

resourceDetailsPage :: ResourceView -> ResourceUsage -> [User] -> Html ()
resourceDetailsPage rv usage users = do
  let d = rvDetails rv
      r = detailResource d
  div_ [class_ "page-head-row"] $ do
    div_ $ do
      h1_ [class_ "page-title"] (toHtml (resName r))
      div_ [class_ "badges"] $ do
        span_ [class_ "badge"] (toHtml (rvKind rv))
        span_ [class_ "badge badge-soft"] (toHtml (rvPurpose rv))
        span_ [class_ "badge badge-soft"] (toHtml (rvCondition rv))
    div_ [class_ "actions"] $ do
      a_ [href_ ("/resources/" <> showId (resId r) <> "/edit"), class_ "btn btn-primary"] "Edit"
      a_ [href_ "/resources", class_ "btn btn-ghost"] "Back"
  div_ [class_ "cards cards-4"] $ do
    card ("Uses", T.pack (show (ruUses usage)))
    card ("Unique users", T.pack (show (ruUniqueUsers usage)))
    card ("Last used", maybe "—" formatDateTime (ruLastUsed usage))
  panel "Annotation" (p_ [class_ "prose"] (toHtml (resAnnotation r)))
  div_ [class_ "grid-2"] $ do
    panel "Authors" $
      if null (detailAuthors d)
        then emptyState "No authors."
        else ul_ [class_ "list"] $ mapM_ (\a -> li_ (toHtml (authorName a))) (detailAuthors d)
    panel "Links" $
      if null (detailUrls d)
        then emptyState "No URLs."
        else ul_ [class_ "list"] $ mapM_ urlItem (detailUrls d)
  div_ [class_ "grid-2"] $ do
    panel "Metadata" $ dl_ [class_ "meta"] $ do
      metaRow "Opened" (formatDay (resOpenedOn r))
      metaRow "Term" (resTermText r)
      metaRow "Valid until" (maybe "—" formatDay (resValidUntil r))
    panel "Record usage" $
      if null users
        then emptyState "Create a user first."
        else form_ [method_ "post", action_ ("/resources/" <> showId (resId r) <> "/usage")] $ do
          label_ [class_ "field"] $ do
            span_ "User"
            select_ [name_ "userId", class_ "input"] $
              mapM_ (\u -> option_ [value_ (showId (userId u))] (toHtml (userName u))) users
          label_ [class_ "field"] $ do
            span_ "Action"
            select_ [name_ "action", class_ "input"] $ do
              option_ [value_ "view"] "view"
              option_ [value_ "download"] "download"
              option_ [value_ "open"] "open"
          button_ [type_ "submit", class_ "btn btn-primary"] "Save usage"
  form_ [method_ "post", action_ ("/resources/" <> showId (resId r) <> "/delete")] $
    button_ [type_ "submit", class_ "btn btn-danger"] "Delete this resource"
  where
    urlItem :: ResourceUrl -> Html ()
    urlItem u =
      li_ $ a_ [href_ (urlAddress u), target_ "_blank", rel_ "noopener"]
              (toHtml (urlAddress u <> maybe "" (\l -> " (" <> l <> ")") (urlLabel u)))
    metaRow :: Text -> Text -> Html ()
    metaRow k v = do
      dt_ (toHtml k)
      dd_ (toHtml v)
