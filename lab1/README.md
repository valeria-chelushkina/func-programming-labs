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

## Project layout

```
dept-resources.cabal            build configuration
cabal.project
app/Main.hs                     entry point + read-only smoke test
src/Model/Resource.hs           pure domain type, no IO
src/Repository/Class.hs         FromRow + Repository classes
src/Repository/Resource.hs      instances for the resources table
src/Db/Config.hs                DbConfig + defaultConfig
src/Db/Connection.hs            withConnection / withTransaction
src/Ui/Render.hs                console formatting
sql/schema.sql                  9 tables
```

Planned additions (same pattern):

```
src/Model/Author.hs             src/Repository/Author.hs
src/Model/User.hs               src/Repository/User.hs
src/Model/Filters.hs            src/Repository/Search.hs
src/Service/Resource.hs         src/Service/Stats.hs
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

1. Domain types for the remaining entities (`Author`, `User`, `ResourceUrl`, ...).
2. `FromRow` / `Repository` instances for them.
3. Write path (`insert`, `update`, `delete`) in `src/Service/`.
4. Search and statistics queries.
5. Console UI in `app/Main.hs` + `src/Ui/Menu.hs`.

