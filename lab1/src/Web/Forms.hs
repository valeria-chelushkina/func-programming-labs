{-# LANGUAGE OverloadedStrings #-}

module Web.Forms
  ( ResourceForm (..)
  , emptyResourceForm
  , AuthorForm (..)
  , emptyAuthorForm
  , UserForm (..)
  , emptyUserForm
  , ResourceView (..)
  ) where

import Data.Text (Text)
import Model.Resource (ResourceDetails)

data ResourceForm = ResourceForm
  { formName        :: Text
  , formAnnotation  :: Text
  , formKind        :: Text
  , formPurpose     :: Text
  , formCondition   :: Text
  , formOpened      :: Text
  , formTerm        :: Text
  , formValid       :: Text
  , formAuthors     :: [Text]
  , formUrls        :: Text
  } deriving (Show, Eq)

emptyResourceForm :: ResourceForm
emptyResourceForm = ResourceForm
  { formName = ""
  , formAnnotation = ""
  , formKind = ""
  , formPurpose = ""
  , formCondition = ""
  , formOpened = ""
  , formTerm = ""
  , formValid = ""
  , formAuthors = []
  , formUrls = ""
  }

data AuthorForm = AuthorForm
  { formAuthorName        :: Text
  , formAuthorEmail       :: Text
  , formAuthorAffiliation :: Text
  } deriving (Show, Eq)

emptyAuthorForm :: AuthorForm
emptyAuthorForm = AuthorForm "" "" ""

data UserForm = UserForm
  { formUserName       :: Text
  , formUserEmail      :: Text
  , formUserRole       :: Text
  , formUserDepartment :: Text
  } deriving (Show, Eq)

emptyUserForm :: UserForm
emptyUserForm = UserForm "" "" "student" ""

data ResourceView = ResourceView
  { rvDetails   :: ResourceDetails
  , rvKind      :: Text
  , rvPurpose   :: Text
  , rvCondition :: Text
  }
