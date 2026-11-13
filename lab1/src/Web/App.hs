{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Web.App
  ( runServer
  ) where

import Control.Concurrent (forkIO)
import Control.Concurrent.MVar (MVar, newMVar, withMVar)
import Control.Monad.IO.Class (liftIO)
import Data.List (find)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import Data.Time.Calendar (Day)
import Data.Time.Format (defaultTimeLocale, formatTime, parseTimeM)
import Data.Word (Word32)
import Database.MySQL.Base (MySQLConn)
import Lucid (Html, renderText)
import Network.Wai.Handler.Warp (setHost, setPort)
import Text.Read (readMaybe)
import Web.Scotty
  ( ActionM
  , Options (..)
  , ScottyM
  , defaultOptions
  , formParams
  , get
  , html
  , pathParamMaybe
  , post
  , queryParams
  , redirect
  , scottyOpts
  )

import Db.Config (defaultConfig)
import Db.Connection (withConnection)
import Model.Author (Author (..), AuthorDraft (..))
import Model.Filters (ResourceFilter (..), emptyFilter)
import Model.Lookup (Kind (..), Purpose (..), UsageCondition (..))
import Model.Resource (Resource (..), ResourceDetails (..), ResourceDraft (..))
import Model.ResourceUrl (ResourceUrl (..), ResourceUrlDraft (..))
import Model.Stats (UsageRecord (..), actionFromText)
import Model.User (User (..), UserDraft (..), roleFromText, roleToText)
import Repository.Author ()
import Repository.Class (Repository (..))
import Repository.Resource ()
import Repository.User ()
import Service.Author
import Service.Lookup
import Service.Resource
import Service.Stats
import Service.User
import Web.Components (showId)
import Web.Forms
  ( AuthorForm (..)
  , ResourceForm (..)
  , ResourceView (..)
  , UserForm (..)
  , emptyAuthorForm
  , emptyResourceForm
  , emptyUserForm
  )
import Web.Layout (layout)
import Web.Pages.Authors (authorFormPage, authorsPage)
import Web.Pages.Dashboard (dashboardPage)
import Web.Pages.NotFound (notFoundPage)
import Web.Pages.ResourceDetails (resourceDetailsPage)
import Web.Pages.ResourceForm (resourceFormPage)
import Web.Pages.Resources (resourcesPage)
import Web.Pages.Stats (statsPage)
import Web.Pages.Users (userFormPage, usersPage)

runServer :: IO ()
runServer = withConnection defaultConfig $ \conn -> do
  var <- newMVar conn
  putStrLn "Dashboard: http://127.0.0.1:8080  (also http://localhost:8080)"
  _ <- forkIO $ scottyOpts (opts "*6") (app var)
  scottyOpts (opts "*4") (app var)
  where
    opts host = defaultOptions
      { settings = setHost host (setPort 8080 (settings defaultOptions))
      }

app :: MVar MySQLConn -> ScottyM ()
app var = do
  get "/" $ dashboardH var

  get "/resources" $ resourcesH var
  get "/resources/new" $ newResourceH var
  post "/resources" $ createResourceH var
  get "/resources/:id" $ detailsH var
  get "/resources/:id/edit" $ editResourceH var
  post "/resources/:id" $ updateResourceH var
  post "/resources/:id/delete" $ deleteResourceH var
  post "/resources/:id/usage" $ usageH var

  get "/authors" $ authorsH var
  get "/authors/new" $ newAuthorH var
  post "/authors" $ createAuthorH var
  get "/authors/:id/edit" $ editAuthorH var
  post "/authors/:id" $ updateAuthorH var

  get "/users" $ usersH var
  get "/users/new" $ newUserH var
  post "/users" $ createUserH var
  get "/users/:id/edit" $ editUserH var
  post "/users/:id" $ updateUserH var

  get "/stats" $ statsH var

-- Dashboard ----------------------------------------------------------------

dashboardH :: MVar MySQLConn -> ActionM ()
dashboardH var = do
  (nres, nauth, nusers, nusage, top) <- db var $ \conn -> do
    nres   <- length <$> findAll @Resource conn
    nauth  <- length <$> findAll @Author conn
    nusers <- length <$> findAll @User conn
    nusage <- totalUsage conn
    top    <- topResources conn 5
    pure (nres, nauth, nusers, nusage, top)
  respond $ layout "Dashboard" "dashboard" $
    dashboardPage
      [ ("Resources", T.pack (show nres))
      , ("Authors", T.pack (show nauth))
      , ("Users", T.pack (show nusers))
      , ("Usage records", T.pack (show nusage))
      ]
      top

-- Resources ----------------------------------------------------------------

resourcesH :: MVar MySQLConn -> ActionM ()
resourcesH var = do
  ps <- queryParams
  let q       = pget "q" ps
      kind    = readW32 (pget "kind" ps)
      purpose = readW32 (pget "purpose" ps)
      flt     = emptyFilter { rfText = q, rfKindId = kind, rfPurposeId = purpose }
  (ks, prs, cs, ds) <- db var $ \conn -> do
    ks  <- listKinds conn
    prs <- listPurposes conn
    cs  <- listConditions conn
    ds  <- searchResourceDetails conn flt
    pure (ks, prs, cs, ds)
  let rows = map (toView ks prs cs) ds
  respond $ layout "Resources" "resources" $
    resourcesPage q ks prs rows

detailsH :: MVar MySQLConn -> ActionM ()
detailsH var = do
  mid <- idParam
  case mid of
    Nothing -> notFound
    Just rid -> do
      result <- db var $ \conn -> do
        md <- getResourceDetails conn rid
        case md of
          Nothing -> pure Nothing
          Just d  -> do
            ks  <- listKinds conn
            prs <- listPurposes conn
            cs  <- listConditions conn
            u   <- resourceUsage conn rid
            us  <- listUsers conn
            pure (Just (toView ks prs cs d, u, us))
      case result of
        Nothing -> notFound
        Just (rv, usage, us) ->
          respond $ layout (resName (detailResource (rvDetails rv))) "resources" $
            resourceDetailsPage rv usage us

newResourceH :: MVar MySQLConn -> ActionM ()
newResourceH var = do
  (ks, prs, cs, as) <- resourceLookups var
  respond $ layout "New resource" "resources" $
    resourceFormPage "/resources" Nothing ks prs cs as emptyResourceForm

createResourceH :: MVar MySQLConn -> ActionM ()
createResourceH var = do
  ps <- formParams
  let f = buildResourceForm ps
  case parseResourceDraft f of
    Left err -> renderResourceForm var "/resources" (Just (T.pack err)) f
    Right draft -> do
      r <- db var $ \conn -> createResource conn draft
      case r of
        Left err -> renderResourceForm var "/resources" (Just (T.pack err)) f
        Right _  -> redirectT "/resources"

editResourceH :: MVar MySQLConn -> ActionM ()
editResourceH var = do
  mid <- idParam
  case mid of
    Nothing -> notFound
    Just rid -> do
      md <- db var $ \conn -> getResourceDetails conn rid
      case md of
        Nothing -> notFound
        Just d  -> do
          (ks, prs, cs, as) <- resourceLookups var
          respond $ layout "Edit resource" "resources" $
            resourceFormPage ("/resources/" <> showId rid) Nothing ks prs cs as
              (formFromDetails d)

updateResourceH :: MVar MySQLConn -> ActionM ()
updateResourceH var = do
  mid <- idParam
  case mid of
    Nothing -> notFound
    Just rid -> do
      ps <- formParams
      let f = buildResourceForm ps
      case parseResourceDraft f of
        Left err -> renderResourceForm var ("/resources/" <> showId rid) (Just (T.pack err)) f
        Right draft -> do
          r <- db var $ \conn -> editResource conn rid draft
          case r of
            Left err -> renderResourceForm var ("/resources/" <> showId rid) (Just (T.pack err)) f
            Right () -> redirectT ("/resources/" <> showId rid)

deleteResourceH :: MVar MySQLConn -> ActionM ()
deleteResourceH var = do
  mid <- idParam
  case mid of
    Nothing -> notFound
    Just rid -> do
      _ <- db var $ \conn -> removeResource conn rid
      redirectT "/resources"

usageH :: MVar MySQLConn -> ActionM ()
usageH var = do
  mid <- idParam
  ps  <- formParams
  case (mid, readW32 (pget "userId" ps), actionFromText (pget "action" ps), readInt (pget "minutes" ps)) of
    (Just rid, Just uid, Right act, Just mins) -> do
      _ <- db var $ \conn ->
        recordUsage conn (UsageRecord uid rid act mins)
      redirectT ("/resources/" <> showId rid)
    (Just rid, _, _, _) -> redirectT ("/resources/" <> showId rid)
    _                   -> notFound

-- Authors ------------------------------------------------------------------

authorsH :: MVar MySQLConn -> ActionM ()
authorsH var = do
  as <- db var listAuthors
  respond $ layout "Authors" "authors" (authorsPage as)

newAuthorH :: MVar MySQLConn -> ActionM ()
newAuthorH _ =
  respond $ layout "New author" "authors" $
    authorFormPage "/authors" Nothing emptyAuthorForm

createAuthorH :: MVar MySQLConn -> ActionM ()
createAuthorH var = do
  ps <- formParams
  let f = buildAuthorForm ps
  case parseAuthorDraft f of
    Left err -> respondAuthorForm "/authors" (Just (T.pack err)) f
    Right d  -> do
      r <- db var $ \conn -> createAuthor conn d
      case r of
        Left err -> respondAuthorForm "/authors" (Just (T.pack err)) f
        Right _  -> redirectT "/authors"

editAuthorH :: MVar MySQLConn -> ActionM ()
editAuthorH var = do
  mid <- idParam
  case mid of
    Nothing -> notFound
    Just aid -> do
      ma <- db var $ \conn -> getAuthor conn aid
      case ma of
        Nothing -> notFound
        Just a  ->
          respond $ layout "Edit author" "authors" $
            authorFormPage ("/authors/" <> showId aid) Nothing
              (AuthorForm (authorName a)
                          (maybe "" id (authorEmail a))
                          (maybe "" id (authorAffiliation a)))

updateAuthorH :: MVar MySQLConn -> ActionM ()
updateAuthorH var = do
  mid <- idParam
  case mid of
    Nothing -> notFound
    Just aid -> do
      ps <- formParams
      let f = buildAuthorForm ps
      case parseAuthorDraft f of
        Left err -> respondAuthorForm ("/authors/" <> showId aid) (Just (T.pack err)) f
        Right d  -> do
          r <- db var $ \conn -> editAuthor conn aid d
          case r of
            Left err -> respondAuthorForm ("/authors/" <> showId aid) (Just (T.pack err)) f
            Right () -> redirectT "/authors"

-- Users --------------------------------------------------------------------

usersH :: MVar MySQLConn -> ActionM ()
usersH var = do
  us <- db var listUsers
  respond $ layout "Users" "users" (usersPage us)

newUserH :: MVar MySQLConn -> ActionM ()
newUserH _ =
  respond $ layout "New user" "users" $
    userFormPage "/users" Nothing emptyUserForm

createUserH :: MVar MySQLConn -> ActionM ()
createUserH var = do
  ps <- formParams
  let f = buildUserForm ps
  case parseUserDraft f of
    Left err -> respondUserForm "/users" (Just (T.pack err)) f
    Right d  -> do
      r <- db var $ \conn -> createUser conn d
      case r of
        Left err -> respondUserForm "/users" (Just (T.pack err)) f
        Right _  -> redirectT "/users"

editUserH :: MVar MySQLConn -> ActionM ()
editUserH var = do
  mid <- idParam
  case mid of
    Nothing -> notFound
    Just uid -> do
      mu <- db var $ \conn -> getUser conn uid
      case mu of
        Nothing -> notFound
        Just u  ->
          respond $ layout "Edit user" "users" $
            userFormPage ("/users/" <> showId uid) Nothing
              (UserForm (userName u) (userEmail u)
                        (roleToText (userRole u))
                        (maybe "" id (userDepartment u)))

updateUserH :: MVar MySQLConn -> ActionM ()
updateUserH var = do
  mid <- idParam
  case mid of
    Nothing -> notFound
    Just uid -> do
      ps <- formParams
      let f = buildUserForm ps
      case parseUserDraft f of
        Left err -> respondUserForm ("/users/" <> showId uid) (Just (T.pack err)) f
        Right d  -> do
          r <- db var $ \conn -> editUser conn uid d
          case r of
            Left err -> respondUserForm ("/users/" <> showId uid) (Just (T.pack err)) f
            Right () -> redirectT "/users"

-- Statistics ---------------------------------------------------------------

statsH :: MVar MySQLConn -> ActionM ()
statsH var = do
  (total, rows, userRows) <- db var $ \conn -> do
    total <- totalUsage conn
    rs <- findAll @Resource conn
    rows <- mapM (\r -> do
      u <- resourceUsage conn (resId r)
      pure (r, u)) rs
    us <- listUsers conn
    userRows <- mapM (\u -> do
      n <- userUsageCount conn (userId u)
      pure (u, n)) us
    pure (total, rows, userRows)
  respond $ layout "Statistics" "stats" (statsPage total rows userRows)

-- Helpers ------------------------------------------------------------------

db :: MVar MySQLConn -> (MySQLConn -> IO a) -> ActionM a
db var action = liftIO (withMVar var action)

respond :: Html () -> ActionM ()
respond page = html (renderText page)

redirectT :: Text -> ActionM a
redirectT = redirect . TL.fromStrict

respondAuthorForm :: Text -> Maybe Text -> AuthorForm -> ActionM ()
respondAuthorForm action merr f =
  respond $ layout "Author" "authors" (authorFormPage action merr f)

respondUserForm :: Text -> Maybe Text -> UserForm -> ActionM ()
respondUserForm action merr f =
  respond $ layout "User" "users" (userFormPage action merr f)

resourceLookups :: MVar MySQLConn
                -> ActionM ([Kind], [Purpose], [UsageCondition], [Author])
resourceLookups var = db var $ \conn ->
  (,,,) <$> listKinds conn <*> listPurposes conn <*> listConditions conn <*> listAuthors conn

renderResourceForm :: MVar MySQLConn -> Text -> Maybe Text -> ResourceForm -> ActionM ()
renderResourceForm var action merr f = do
  (ks, prs, cs, as) <- resourceLookups var
  respond $ layout "Resource" "resources" $
    resourceFormPage action merr ks prs cs as f

notFound :: ActionM ()
notFound = respond $ layout "Not found" "" notFoundPage

toView :: [Kind] -> [Purpose] -> [UsageCondition] -> ResourceDetails -> ResourceView
toView ks prs cs d =
  ResourceView
    { rvDetails   = d
    , rvKind      = lookupName kindId kindName (resKindId r) ks
    , rvPurpose   = lookupName purposeId purposeName (resPurposeId r) prs
    , rvCondition = lookupName conditionId conditionName (resConditionId r) cs
    }
  where
    r = detailResource d

lookupName :: (a -> Word32) -> (a -> Text) -> Word32 -> [a] -> Text
lookupName key value k xs =
  maybe "—" value (find ((== k) . key) xs)

idParam :: ActionM (Maybe Word32)
idParam = do
  mt <- pathParamMaybe "id" :: ActionM (Maybe Text)
  pure (mt >>= readW32)

pget :: Text -> [(Text, Text)] -> Text
pget k ps = fromMaybe "" (lookup k ps)

pgets :: Text -> [(Text, Text)] -> [Text]
pgets k ps = [v | (k', v) <- ps, k' == k]

readW32 :: Text -> Maybe Word32
readW32 = readMaybe . T.unpack

readInt :: Text -> Maybe Int
readInt = readMaybe . T.unpack

-- Forms --------------------------------------------------------------------

buildResourceForm :: [(Text, Text)] -> ResourceForm
buildResourceForm ps = ResourceForm
  { formName        = pget "name" ps
  , formAnnotation  = pget "annotation" ps
  , formKind        = pget "kind" ps
  , formPurpose     = pget "purpose" ps
  , formCondition   = pget "condition" ps
  , formOpened      = pget "openedOn" ps
  , formTerm        = pget "termText" ps
  , formValid       = pget "validUntil" ps
  , formAuthors     = pgets "authorIds" ps
  , formUrls        = pget "urls" ps
  }

parseResourceDraft :: ResourceForm -> Either String ResourceDraft
parseResourceDraft f = do
  k <- maybe (Left "choose a kind") Right (readW32 (formKind f))
  p <- maybe (Left "choose a purpose") Right (readW32 (formPurpose f))
  c <- maybe (Left "choose usage conditions") Right (readW32 (formCondition f))
  opened <- maybe (Left "opened date must be YYYY-MM-DD") Right (parseDay (formOpened f))
  valid <- if T.null (T.strip (formValid f))
             then Right Nothing
             else Just <$> maybe (Left "valid-until date must be YYYY-MM-DD") Right (parseDay (formValid f))
  authors <- traverse (\t -> maybe (Left "invalid author id") Right (readW32 t)) (formAuthors f)
  let urls = [ ResourceUrlDraft u Nothing False
             | line <- T.lines (formUrls f)
             , let u = T.strip line
             , not (T.null u)
             ]
  pure ResourceDraft
    { draftName        = formName f
    , draftAnnotation  = formAnnotation f
    , draftKindId      = k
    , draftPurposeId   = p
    , draftConditionId = c
    , draftOpenedOn    = opened
    , draftTermText    = formTerm f
    , draftValidUntil  = valid
    , draftAuthorIds   = authors
    , draftUrls        = urls
    }

formFromDetails :: ResourceDetails -> ResourceForm
formFromDetails d = ResourceForm
  { formName        = resName r
  , formAnnotation  = resAnnotation r
  , formKind        = showId (resKindId r)
  , formPurpose     = showId (resPurposeId r)
  , formCondition   = showId (resConditionId r)
  , formOpened      = showDay (resOpenedOn r)
  , formTerm        = resTermText r
  , formValid       = maybe "" showDay (resValidUntil r)
  , formAuthors     = map (showId . authorId) (detailAuthors d)
  , formUrls        = T.intercalate "\n" (map urlAddress (detailUrls d))
  }
  where
    r = detailResource d

buildAuthorForm :: [(Text, Text)] -> AuthorForm
buildAuthorForm ps = AuthorForm
  { formAuthorName        = pget "name" ps
  , formAuthorEmail       = pget "email" ps
  , formAuthorAffiliation = pget "affiliation" ps
  }

parseAuthorDraft :: AuthorForm -> Either String AuthorDraft
parseAuthorDraft f =
  pure AuthorDraft
    { authorDraftName        = T.strip (formAuthorName f)
    , authorDraftEmail       = nonEmpty (formAuthorEmail f)
    , authorDraftAffiliation = nonEmpty (formAuthorAffiliation f)
    }

buildUserForm :: [(Text, Text)] -> UserForm
buildUserForm ps = UserForm
  { formUserName       = pget "name" ps
  , formUserEmail      = pget "email" ps
  , formUserRole       = pget "role" ps
  , formUserDepartment = pget "department" ps
  }

parseUserDraft :: UserForm -> Either String UserDraft
parseUserDraft f = do
  role <- roleFromText (formUserRole f)
  pure UserDraft
    { userDraftName       = T.strip (formUserName f)
    , userDraftEmail      = T.strip (formUserEmail f)
    , userDraftRole       = role
    , userDraftDepartment = nonEmpty (formUserDepartment f)
    }

nonEmpty :: Text -> Maybe Text
nonEmpty t =
  let s = T.strip t
   in if T.null s then Nothing else Just s

parseDay :: Text -> Maybe Day
parseDay = parseTimeM True defaultTimeLocale "%Y-%m-%d" . T.unpack

showDay :: Day -> Text
showDay = T.pack . formatTime defaultTimeLocale "%Y-%m-%d"
