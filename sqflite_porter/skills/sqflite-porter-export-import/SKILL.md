---
name: sqflite-porter-export-import
description: >-
  Use when reading or maintaining legacy Flutter code that dumps a sqflite
  database to SQL with sqflite_porter: dbExportSql, dbImportSql, the
  package:sqflite_porter/sqflite_porter.dart import, backup/restore of a
  sqflite Database. This package is deprecated in favour of
  sqflite_common_porter, so also use it when migrating off it.
---

# Legacy SQL export and import (sqflite_porter)

`sqflite_porter` dumps a Flutter `sqflite` `Database` to a `List<String>` of
SQL statements and replays them into an empty database. Its README marks it
**deprecated**: new code should use the `sqflite_common_porter` package (same
repo, `path: sqflite_common_porter`), which works with every sqflite flavour
(`sqflite`, `sqflite_common_ffi`, a server client), exports the database
version and adds `openDatabaseFromSqlImport`.

## Guidelines

* Prefer `sqflite_common_porter` for anything new. This package exists only
  for existing Flutter apps that already depend on it.
* Dependency (git only, this package is **not** published on pub.dev):
  ```yaml
  dependencies:
    sqflite_porter:
      git:
        url: https://github.com/tekartik/sqflite_more
        path: sqflite_porter
      version: '>=0.2.0'
  ```
* Import `package:sqflite_porter/sqflite_porter.dart`. It exports exactly two
  functions, `dbExportSql` and `dbImportSql`, and nothing else: add
  `package:sqflite/sqflite.dart` for `Database`, `openDatabase`,
  `getDatabasesPath`.
* `Future<List<String>> dbExportSql(Database db)` runs inside one transaction
  and returns the `CREATE TABLE` statements, one
  `INSERT INTO <table> VALUES (...);` per row, then
  `DELETE FROM sqlite_sequence;` plus the `sqlite_sequence` rows, then the
  `CREATE VIEW` / `CREATE TRIGGER` statements. Every statement ends with `;`.
* The database **version is not exported** (unlike `sqflite_common_porter`):
  reopen the restored database with the same `version` in `openDatabase`, or
  the `onCreate`/`onUpgrade` callbacks will fire on an already populated
  database.
* `dbExportSql` queries `sqlite_sequence` unconditionally, so it throws on a
  database that has no `AUTOINCREMENT` column (that system table only exists
  once something used `AUTOINCREMENT`). This is fixed in
  `sqflite_common_porter`; work around it by adding one `AUTOINCREMENT`
  table, or migrate.
* `Future dbImportSql(Database db, List<String> sqlStatements)` executes the
  statements through a single `Batch` committed with `noResult: true`. There
  is no batch-size option, so a very large export is committed in one go.
* **The target database must be empty**: replaying `CREATE TABLE` on an
  existing schema fails. Either delete the file first
  (`deleteDatabase(path)`) or import from `onCreate`.
* Values are escaped by `dbExportSql`: `null` becomes `NULL`, `List<int>`
  blobs become `x'0a1b'` hex literals, text has its `'` doubled. Never build
  those statements by hand.
* System tables (`sqlite_*` other than `sqlite_sequence`, `android_metadata`)
  are skipped, so an Android export can be imported on iOS.
* Migration to `sqflite_common_porter`: swap the dependency and the import,
  keep the same `dbExportSql` / `dbImportSql` calls, and note that the new
  statements have no trailing `;` and gain a final
  `PRAGMA user_version = <n>`; a dump produced by one package still imports
  fine with the other.
* Tests use `flutter_test` and need a real device/emulator (or
  `sqflite_common_ffi` + `databaseFactoryFfi` on the host) because `sqflite`
  is a plugin.

## Examples

### Export a database to a SQL script

```dart
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_porter/sqflite_porter.dart';

/// Returns the database content as a single SQL script.
Future<String> exportDatabase(Database db) async {
  var statements = await dbExportSql(db);
  return statements.join('\n');
}
```

### Restore an export into a fresh database

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_porter/sqflite_porter.dart';

/// [export] is a previous [dbExportSql] result.
/// The version is not part of the export: pass the one the app expects.
Future<Database> restoreDatabase(
  String dbName,
  List<String> export, {
  required int version,
}) async {
  var path = join(await getDatabasesPath(), dbName);
  // The import needs an empty database.
  await deleteDatabase(path);
  var db = await openDatabase(path);
  await dbImportSql(db, export);
  await db.close();

  // Reopen with the expected version so onCreate does not run again.
  return await openDatabase(path, version: version);
}
```

### Seed a database during onCreate

```dart
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_porter/sqflite_porter.dart';

Future<Database> openSeeded(String path, List<String> seedExport) async {
  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Empty database here: safe to replay the statements.
      await dbImportSql(db, seedExport);
    },
  );
}
```

## Common mistakes

* Using this package in new code instead of `sqflite_common_porter`.
* Expecting the database version to survive the round trip: it does not.
* Calling `dbExportSql` on a database with no `AUTOINCREMENT` table and
  hitting a missing `sqlite_sequence` error.
* Importing into a database that already has the tables.
* Assuming `sqflite_porter.dart` re-exports `sqflite`: it exports only
  `dbExportSql` and `dbImportSql`.
