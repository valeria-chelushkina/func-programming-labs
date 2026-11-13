{-# LANGUAGE OverloadedStrings #-}

module Web.Pages.Users
  ( usersPage
  , userFormPage
  ) where

import Data.Text (Text)
import Lucid

import Model.User (User (..), roleToText)
import Web.Components (alert, pageHead, selectedAttr, showId)
import Web.Forms (UserForm (..))

usersPage :: [User] -> Html ()
usersPage users = do
  div_ [class_ "page-head-row"] $ do
    pageHead "Users" "Admin view of students, teachers and staff"
    a_ [href_ "/users/new", class_ "btn btn-primary"] "Add user"
  table_ [class_ "table"] $ do
    thead_ $ tr_ $ do
      th_ "ID"
      th_ "Name"
      th_ "Email"
      th_ "Role"
      th_ "Department"
      th_ [class_ "actions-col"] "Actions"
    tbody_ $ mapM_ row users
  where
    row :: User -> Html ()
    row u = tr_ $ do
      td_ [class_ "muted"] (toHtml (showId (userId u)))
      td_ (toHtml (userName u))
      td_ (toHtml (userEmail u))
      td_ (span_ [class_ "badge"] (toHtml (roleToText (userRole u))))
      td_ (toHtml (maybe "—" id (userDepartment u)))
      td_ [class_ "actions-col"] $
        a_ [href_ ("/users/" <> showId (userId u) <> "/edit"), class_ "btn btn-sm btn-ghost"] "Edit"

userFormPage :: Text -> Maybe Text -> UserForm -> Html ()
userFormPage action merr f = do
  pageHead "User" "Create or update a user"
  maybe (pure ()) alert merr
  form_ [method_ "post", action_ action, class_ "form"] $ do
    label_ [class_ "field"] $ do
      span_ "Full name *"
      input_ [type_ "text", name_ "name", value_ (formUserName f), class_ "input", required_ ""]
    label_ [class_ "field"] $ do
      span_ "Email *"
      input_ [type_ "email", name_ "email", value_ (formUserEmail f), class_ "input", required_ ""]
    div_ [class_ "grid-2"] $ do
      selectRole (formUserRole f)
      label_ [class_ "field"] $ do
        span_ "Department"
        input_ [type_ "text", name_ "department", value_ (formUserDepartment f), class_ "input"]
    div_ [class_ "actions"] $ do
      button_ [type_ "submit", class_ "btn btn-primary"] "Save"
      a_ [href_ "/users", class_ "btn btn-ghost"] "Cancel"
  where
    selectRole :: Text -> Html ()
    selectRole selected =
      label_ [class_ "field"] $ do
        span_ "Role *"
        select_ [name_ "role", class_ "input"] $ do
          option_ ([value_ "student"] <> selectedAttr (selected == "student")) "Student"
          option_ ([value_ "teacher"] <> selectedAttr (selected == "teacher")) "Teacher"
          option_ ([value_ "staff"] <> selectedAttr (selected == "staff")) "Staff"
