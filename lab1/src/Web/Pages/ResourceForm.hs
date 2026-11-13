{-# LANGUAGE OverloadedStrings #-}

module Web.Pages.ResourceForm
  ( resourceFormPage
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Lucid

import Model.Author (Author (..))
import Model.Lookup (Kind (..), Purpose (..), UsageCondition (..))
import Web.Components
  ( alert
  , checkedAttr
  , pageHead
  , selectField
  , showId
  )
import Web.Forms (ResourceForm (..))

resourceFormPage :: Text -> Maybe Text -> [Kind] -> [Purpose] -> [UsageCondition]
                 -> [Author] -> ResourceForm -> Html ()
resourceFormPage action merr kinds purposes conditions authors f = do
  pageHead (if T.null (formName f) then "New resource" else "Edit resource")
           "Fields marked with * are required"
  maybe (pure ()) alert merr
  form_ [method_ "post", action_ action, class_ "form"] $ do
    label_ [class_ "field"] $ do
      span_ "Name *"
      input_ [type_ "text", name_ "name", value_ (formName f), class_ "input", required_ ""]
    label_ [class_ "field"] $ do
      span_ "Annotation *"
      textarea_ [name_ "annotation", rows_ "5", class_ "input", required_ ""] (toHtml (formAnnotation f))
    div_ [class_ "grid-3"] $ do
      selectField "kind" "Kind *" (formKind f) (map (\k -> (showId (kindId k), kindName k)) kinds)
      selectField "purpose" "Purpose *" (formPurpose f) (map (\p -> (showId (purposeId p), purposeName p)) purposes)
      selectField "condition" "Conditions *" (formCondition f)
                  (map (\c -> (showId (conditionId c), conditionName c)) conditions)
    div_ [class_ "grid-3"] $ do
      label_ [class_ "field"] $ do
        span_ "Opened on *"
        input_ [type_ "date", name_ "openedOn", value_ (formOpened f), class_ "input", required_ ""]
      label_ [class_ "field"] $ do
        span_ "Term *"
        input_ [type_ "text", name_ "termText", value_ (formTerm f), class_ "input", required_ ""]
      label_ [class_ "field"] $ do
        span_ "Valid until"
        input_ [type_ "date", name_ "validUntil", value_ (formValid f), class_ "input"]
    fieldset_ [class_ "field"] $ do
      legend_ "Authors *"
      div_ [class_ "checks"] $
        mapM_ (\a -> label_ [class_ "check"] $ do
          input_ ([ type_ "checkbox", name_ "authorIds", value_ (showId (authorId a)) ]
                    <> checkedAttr (showId (authorId a) `elem` formAuthors f))
          toHtml (authorName a)) authors
    label_ [class_ "field"] $ do
      span_ "URLs (one per line)"
      textarea_ [name_ "urls", rows_ "4", class_ "input", placeholder_ "https://…"] (toHtml (formUrls f))
    div_ [class_ "actions"] $ do
      button_ [type_ "submit", class_ "btn btn-primary"] "Save"
      a_ [href_ "/resources", class_ "btn btn-ghost"] "Cancel"
