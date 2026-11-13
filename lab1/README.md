# dept-resources

Skeleton for the course project "Information resources of the department"
(Functional Programming). Haskell + MySQL.

**Status:** build/DB foundation only. No UI, no CRUD, no search yet.

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

## 3. Build and run

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
delete, rollback), author CRUD, and dictionary listings are covered by
manual smoke tests:

```powershell
cabal exec -- runghc -isrc scripts\SmokeCrud.hs
cabal exec -- runghc -isrc scripts\SmokeAuthor.hs
cabal exec -- runghc -isrc scripts\SmokeLookup.hs
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
src/Repository/Class.hs         FromRow + Repository classes
src/Repository/Resource.hs      resource row + authors/URLs, transactional
src/Repository/Author.hs        authors of a resource + create/update
src/Repository/ResourceUrl.hs   URLs of one resource
src/Repository/Lookup.hs        dictionary instances
src/Service/Resource.hs         full resource CRUD use-cases
src/Service/Author.hs           author create/edit/list use-cases
src/Service/Lookup.hs           list/get dictionaries
src/Db/Config.hs                DbConfig + defaultConfig
src/Db/Connection.hs            withConnection / withTransaction
src/Ui/Render.hs                console formatting
scripts/SmokeCrud.hs            manual resource CRUD check
scripts/SmokeAuthor.hs          manual author CRUD check
scripts/SmokeLookup.hs          manual dictionary check
sql/schema.sql                  9 tables
```

Planned additions (same pattern):

```
src/Model/User.hs               src/Repository/User.hs
src/Model/Filters.hs            src/Repository/Search.hs
src/Model/UsageStat.hs          src/Service/Stats.hs
src/Ui/Menu.hs
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

1. `User` and `UsageStat` domain types + repositories (needed for statistics).
2. Search filters (`Model/Filters.hs`, `Repository/Search.hs`).
3. Statistics queries (`Service/Stats.hs`).
4. Console UI in `app/Main.hs` + `src/Ui/Menu.hs`.

