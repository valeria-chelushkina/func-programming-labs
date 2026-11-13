{-# LANGUAGE OverloadedStrings #-}

module Web.Components
  ( pageHead
  , panel
  , alert
  , card
  , emptyState
  , selectField
  , selectedAttr
  , checkedAttr
  , showId
  , formatDay
  , formatDateTime
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Time.Calendar (Day)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (LocalTime)
import Lucid

pageHead :: Text -> Text -> Html ()
pageHead title subtitle = do
  h1_ [class_ "page-title"] (toHtml title)
  p_ [class_ "page-sub"] (toHtml subtitle)

panel :: Text -> Html () -> Html ()
panel title body = do
  section_ [class_ "panel"] $ do
    h2_ [class_ "panel-title"] (toHtml title)
    body

alert :: Text -> Html ()
alert msg = div_ [class_ "alert"] (toHtml msg)

card :: (Text, Text) -> Html ()
card (label, value) =
  div_ [class_ "card"] $ do
    div_ [class_ "card-value"] (toHtml value)
    div_ [class_ "card-label"] (toHtml label)

emptyState :: Text -> Html ()
emptyState msg = p_ [class_ "empty"] (toHtml msg)

selectField :: Text -> Text -> Text -> [(Text, Text)] -> Html ()
selectField name label selected options =
  label_ [class_ "field"] $ do
    span_ (toHtml label)
    select_ [name_ name, class_ "input"] $ do
      option_ [value_ ""] "— select —"
      mapM_ (\(v, l) -> option_ ([value_ v] <> selectedAttr (v == selected)) (toHtml l)) options

selectedAttr :: Bool -> [Attribute]
selectedAttr True  = [selected_ ""]
selectedAttr False = []

checkedAttr :: Bool -> [Attribute]
checkedAttr True  = [checked_]
checkedAttr False = []

showId :: (Show a) => a -> Text
showId = T.pack . show

formatDay :: Day -> Text
formatDay = T.pack . formatTime defaultTimeLocale "%Y-%m-%d"

formatDateTime :: LocalTime -> Text
formatDateTime = T.pack . formatTime defaultTimeLocale "%Y-%m-%d %H:%M"
