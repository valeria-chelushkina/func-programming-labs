# dept-resources

Skeleton for the course project "Information resources of the department"
(Functional Programming). Haskell + MySQL.

**Status:** backend complete — resource/author/user CRUD, search, dictionary
listings, usage statistics. The console UI is the remaining piece.

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

## 4. Build and run

```powershell
cabal update
cabal build
cabal run
```

Expected output:

```
Connected to MySQL 8.4.x
```

If the database is not running, the program prints `Error: ...`
instead of crashing.

## How to check that it works

`cabal run` checks only the read path: it connects, prints the MySQL version,
and lists the `resources` table.

Full CRUD for resources (create with authors/URLs, read details, update,
delete, rollback), author CRUD, dictionary listings, search, user
management, and usage statistics are covered by manual smoke tests:

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
app/Main.hs                     entry point + read-only smoke test
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
src/Ui/Render.hs                console formatting
scripts/SmokeCrud.hs            manual resource CRUD check
scripts/SmokeAuthor.hs          manual author CRUD check
scripts/SmokeLookup.hs          manual dictionary check
scripts/SmokeSearch.hs          manual search check
scripts/SmokeUser.hs            manual user check
scripts/SmokeStats.hs           manual usage statistics check
sql/schema.sql                  9 tables
sql/seed.sql                    demo data (resets the tables)
```

Planned additions (same pattern):

```
src/Ui/Menu.hs                  interactive console menu
sql/seed.sql                    demo data for dictionaries/users/resources
```

## Connection settings

`src/Db/Config.hs` -> `defaultConfig`:

- host: `127.0.0.1`
- port: `3306`
- database: `dept_resources`
- user: `root`
- password: `root`

Change them there if your MySQL setup differs.

## Next steps (not implemented)

1. Console UI in `app/Main.hs` + `src/Ui/Menu.hs`.
2. Polish: show kind/purpose/condition **names** in list/details, config from env vars.

