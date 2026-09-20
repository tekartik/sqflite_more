---
name: sqflite-common-porter-export-import
description: >-
  Use when dumping a sqflite/sqflite_common database to SQL statements or
  restoring one from such a dump with sqflite_common_porter: dbExportSql,
  dbImportSql, openDatabaseFromSqlImport, the
  package:sqflite_common_porter/sqflite_porter.dart import, importing during
  onCreate, backup/restore or seeding an in-memory test database, and the
  mapListToCsv / csvToMapList helpers from
  package:sqflite_common_porter/utils/csv_utils.dart.
---

# SQL export and import (sqflite_common_porter)

`sqflite_common_porter` turns any `sqflite_common` `Database` into a plain
`List<String>` of SQL statements (schema + `INSERT`s + `PRAGMA user_version`)
and replays that list into an empty database. It works with any
`DatabaseFactory` (`sqflite_common_ffi`, `sqflite`, a server client), so it is
the usual way to back up, seed or duplicate a database. The README warns it is
reference code: views and triggers are exported but only lightly tested.

## Guidelines

* Dependency (git only, this package is **not** published on pub.dev):
  ```yaml
  dependencies:
    sqflite_common_porter:
      git:
        url: https://github.com/tekartik/sqflite_more
        path: sqflite_common_porter
      version: '>=0.2.0'
  ```
  For a Flutter app depending on `sqflite` rather than `sqflite_common`, use
  the `sqflite_porter` package (same repo, `path: sqflite_porter`) instead: it
  re-exports the same three functions.
* One import for everything: `package:sqflite_common_porter/sqflite_porter.dart`
  exports exactly `dbExportSql`, `dbImportSql` and `openDatabaseFromSqlImport`.
  It does **not** re-export `sqflite_common`, so add
  `package:sqflite_common/sqlite_api.dart` (or `sqflite_common_ffi/sqflite_ffi.dart`)
  for `Database`, `DatabaseFactory`, `OpenDatabaseOptions`.
* `Future<List<String>> dbExportSql(Database db)` reads `sqlite_master` in a
  single transaction and returns, in order: the `CREATE TABLE` statements,
  one `INSERT INTO <table> VALUES (...)` per row, the `CREATE VIEW` /
  `CREATE TRIGGER` statements, and `PRAGMA user_version = <n>` when the
  version is not 0. An empty database exports to an empty list.
* Statements carry no trailing `;`. Text is escaped by doubling quotes,
  `BLOB`s become `x'0a1b'` hex literals, `null` becomes `NULL`. System tables
  (`sqlite_*`, `android_metadata`) are skipped, except `sqlite_sequence`
  whose content is re-emitted after a `DELETE FROM sqlite_sequence`.
* `Future<void> dbImportSql(Database db, List<String> sqlStatements, {SqlImportOptions? options})`
  replays the statements through a `Batch`. **The database must be empty**:
  importing into a database that already has the tables fails on
  `CREATE TABLE`. Because the export ends with `PRAGMA user_version`, the
  imported database gets the original version back.
* `Future<Database> openDatabaseFromSqlImport(DatabaseFactory factory, String path, List<String> sqlStatements, {SqlImportOptions? options, OpenDatabaseOptions? openDatabaseOptions})`
  is the one-call restore: it deletes `path`, opens it and imports. Do not
  pass a `version`/`onCreate` in `openDatabaseOptions` (the export already
  restores the version); with `inMemoryDatabasePath` pass
  `OpenDatabaseOptions(singleInstance: false)` so each call gets a fresh
  in-memory database.
* The `options` parameter takes a `SqlImportOptions(importBatchSize)` used to
  split a huge import into several batch commits. That class is currently
  **not** exported by `sqflite_porter.dart`; leave `options` null unless you
  import `package:sqflite_common_porter/src/sqlite_porter.dart` directly
  (private API, may break).
* Importing inside `onCreate` is supported and is the idiomatic way to seed a
  versioned database: the database is empty there, and the trailing
  `PRAGMA user_version` is harmless since sqflite sets the version itself.
* Round-tripping is not byte-exact for column order in views/triggers created
  before their table; check an export of your real schema once before relying
  on it in production.
* CSV side helper: `package:sqflite_common_porter/utils/csv_utils.dart`
  re-exports `mapListToCsv(List<Map> mapList, {columns, nullValue})` and
  `csvToMapList(String csv)` from `tekartik_app_csv`. `mapListToCsv` takes
  the result of `db.query(...)` directly; `BLOB` columns are rendered as
  `[1, 2, 3]` lists, so export blobs with `dbExportSql`, not with CSV.
* Tests: `dart test` with `sqflite_common_ffi`'s `databaseFactoryFfi` after
  `sqfliteFfiInit()`, using `inMemoryDatabasePath`.

## Examples

### Export a database to SQL statements

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var factory = databaseFactoryFfi;

  var db = await factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
      },
    ),
  );
  await db.insert('Test', {'value': 'my_value'});

  var export = await dbExportSql(db);
  // [CREATE TABLE Test (...), INSERT INTO Test VALUES (1,'my_value'),
  //  PRAGMA user_version = 1]
  for (var statement in export) {
    print(statement);
  }
  await db.close();
}
```

### Restore an export into a new database file

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';

/// Recreate [path] from a previous [dbExportSql] result.
Future<Database> restore(
  DatabaseFactory factory,
  String path,
  List<String> export,
) async {
  // Deletes path, opens it and replays the statements.
  return await openDatabaseFromSqlImport(factory, path, export);
}
```

### Copy a database to a fresh in-memory one

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';

Future<Database> copyToMemory(DatabaseFactory factory, Database source) async {
  var export = await dbExportSql(source);
  return await openDatabaseFromSqlImport(
    factory,
    inMemoryDatabasePath,
    export,
    // Required so each copy is an independent in-memory database.
    openDatabaseOptions: OpenDatabaseOptions(singleInstance: false),
  );
}
```

### Seed a versioned database during onCreate

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';

Future<Database> openSeeded(
  DatabaseFactory factory,
  String path,
  List<String> seedExport,
) async {
  return await factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        // The database is empty here: safe to import.
        await dbImportSql(db, seedExport);
      },
    ),
  );
}
```

### Export a table as CSV

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_porter/utils/csv_utils.dart';

Future<String> tableToCsv(Database db, String table) async {
  var rows = await db.query(table);
  return mapListToCsv(rows);
}

List<Map<String, Object?>> csvToRows(String csv) => csvToMapList(csv);
```

## Common mistakes

* Importing into a database that already contains the tables: `dbImportSql`
  needs an empty database (use `openDatabaseFromSqlImport`, or import from
  `onCreate`).
* Opening `inMemoryDatabasePath` without `singleInstance: false` and getting
  the previously opened in-memory database back.
* Expecting `sqflite_porter.dart` to re-export `sqflite_common`: import
  `package:sqflite_common/sqlite_api.dart` for `Database` and friends.
* Using `SqlImportOptions` from the public import: it is not exported.
* Using `mapListToCsv` for blob columns: only `dbExportSql` round-trips them.
