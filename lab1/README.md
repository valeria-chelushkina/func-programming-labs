# dept-resources

Skeleton for the course project "Information resources of the department"
(Functional Programming). Haskell + MySQL + a lilac web dashboard.

**Status:** complete web admin dashboard — resource/author/user CRUD, search,
dictionary listings, usage statistics.

## Requirements

- GHC 9.10.3 and cabal 3.16 (already installed)
- Docker (for MySQL) or a local MySQL 8 server

## 1. Start MySQL

```powershell
docker run -d --name fp-mysql -p 3306:3306 `
  -e MYSQL_ROOT_PASSWORD=root `
  -e MYSQL_DATABASE=dept_resources `
  mysql:8.4
```

If the container already exists, just start it:

```powershell
docker start fp-mysql
```

## 2. Create the schema

```powershell
Get-Content .\sql\schema.sql -Raw |
  docker exec -i fp-mysql mysql -uroot -proot dept_resources
```

Check:

```powershell
docker exec -it fp-mysql mysql -uroot -proot dept_resources -e "SHOW TABLES;"
```

Expected: 9 tables.

## 3. Load demo data (optional)

Resets all application tables and inserts dictionaries, authors, users,
10 resources, their links, and 30 usage records:

```powershell
$OutputEncoding = [System.Text.Encoding]::UTF8
Get-Content .\sql\seed.sql -Raw -Encoding UTF8 |
  docker exec -i fp-mysql mysql --default-character-set=utf8mb4 -uroot -proot dept_resources
```

**Warning:** this deletes existing rows in all application tables.

## 4. Run the web dashboard

```powershell
cabal update
cabal build
cabal run
```

Then open **http://localhost:8080** in a browser. Stop the server with `Ctrl+C`.

If the database is not running, the pages show an error instead of crashing.

## How to check that it works

Start the server and open:

- `/` — dashboard with counts and top resources;
- `/resources` — search bar, kind/purpose filters, table;
- `/resources/1` — details, authors, URLs, usage, delete;
- `/resources/new` — create form;
- `/resources/1/edit` — pre-filled edit form;
- `/authors`, `/users` — lists and create/edit forms;
- `/stats` — per-resource and per-user usage.

Full CRUD for resources (create with authors/URLs, read details, update,
delete, rollback), author CRUD, dictionary listings, search, user
management, and usage statistics are also covered by manual smoke tests:

```powershell
cabal exec -- runghc -isrc scripts\SmokeCrud.hs
cabal exec -- runghc -isrc scripts\SmokeAuthor.hs
cabal exec -- runghc -isrc scripts\SmokeLookup.hs
cabal exec -- runghc -isrc scripts\SmokeSearch.hs
cabal exec -- runghc -isrc scripts\SmokeUser.hs
cabal exec -- runghc -isrc scripts\SmokeStats.hs
```

Expected: a sequence of `[PASS]` lines ending with `ALL CHECKS PASSED`.
The scripts create temporary rows and remove them, so they do not touch your data.

## Project layout

```
dept-resources.cabal            build configuration
cabal.project
app/Main.hs                     entry point: starts the web server
src/Web/App.hs                  routes + handlers
src/Web/Layout.hs               page shell + lilac CSS
src/Web/Components.hs           cards, panels, alerts, form controls
src/Web/Forms.hs                form state types (resource/author/user)
src/Web/Pages/Dashboard.hs      dashboard page
src/Web/Pages/Resources.hs      resource list + search
src/Web/Pages/ResourceDetails.hs  one resource + usage
src/Web/Pages/ResourceForm.hs   create/edit resource form
src/Web/Pages/Authors.hs        author list + form
src/Web/Pages/Users.hs          user list + form
src/Web/Pages/Stats.hs          statistics page
src/Web/Pages/NotFound.hs       404 content
src/Model/Resource.hs           Resource, ResourceDraft, ResourceDetails
src/Model/Author.hs             Author + AuthorDraft
src/Model/ResourceUrl.hs        ResourceUrl + input draft
src/Model/Lookup.hs             Kind, Purpose, UsageCondition
src/Model/Filters.hs            ResourceFilter
src/Model/User.hs               User, UserDraft, Role
src/Model/Stats.hs              UsageRecord + report types
src/Repository/Class.hs         FromRow + Repository classes
src/Repository/Resource.hs      resource row + authors/URLs, transactional
src/Repository/Author.hs        authors of a resource + create/update
src/Repository/ResourceUrl.hs   URLs of one resource
src/Repository/Lookup.hs        dictionary instances
src/Repository/Search.hs        SQL search by text/kind/purpose/author
src/Repository/User.hs          users + create/update
src/Repository/Stats.hs         usage inserts + aggregates
src/Service/Resource.hs         full resource CRUD use-cases
src/Service/Author.hs           author create/edit/list use-cases
src/Service/Lookup.hs           list/get dictionaries
src/Service/User.hs             user create/edit/list use-cases
src/Service/Stats.hs            record usage + reports
src/Db/Config.hs                DbConfig + defaultConfig
src/Db/Connection.hs            withConnection / withTransaction
scripts/SmokeCrud.hs            manual resource CRUD check
scripts/SmokeAuthor.hs          manual author CRUD check
scripts/SmokeLookup.hs          manual dictionary check
scripts/SmokeSearch.hs          manual search check
scripts/SmokeUser.hs            manual user check
scripts/SmokeStats.hs           manual usage statistics check
sql/schema.sql                  9 tables
sql/seed.sql                    demo data (resets the tables)
```

Planned additions (optional):

```
authentication / admin login
pagination and flash messages
config from environment variables
```

## Connection settings

`src/Db/Config.hs` -> `defaultConfig`:

- host: `127.0.0.1`
- port: `3306`
- database: `dept_resources`
- user: `root`
- password: `root`

Change them there if your MySQL setup differs.

## Next steps (optional)

1. Admin authentication and roles.
2. Pagination and success/error flash messages.
3. Config from environment variables instead of hardcoded root/root.

