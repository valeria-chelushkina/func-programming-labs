{-# LANGUAGE OverloadedStrings #-}

module Web.Pages.NotFound
  ( notFoundPage
  ) where

import Lucid
import Web.Components (pageHead)

notFoundPage :: Html ()
notFoundPage = do
  pageHead "Not found" "The page or record does not exist"
  a_ [href_ "/", class_ "btn btn-primary"] "Back to dashboard"
