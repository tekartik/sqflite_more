# sqflite_porter

**Deprecated**: use [sqflite_common_porter](../sqflite_common_porter) in new
code. It has the same `dbExportSql` / `dbImportSql`, works with every sqflite
flavour (the `sqflite` plugin, `sqflite_common_ffi`, the web) and adds
`openDatabaseFromSqlImport`.

This package is kept for the Flutter apps that already import
`package:sqflite_porter/sqflite_porter.dart`: it re-exports `dbExportSql` and
`dbImportSql` of sqflite_common_porter (same code, same output) and nothing
else.

## Getting started

Not on pub.dev, a git dependency (Flutter, with the `sqflite` plugin:
Android, iOS, macOS):

```yaml
dependencies:
  sqflite: ">=2.4.3"
  sqflite_porter:
    git:
      url: https://github.com/tekartik/sqflite_more
      path: sqflite_porter
    version: '>=0.2.0'
```

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_porter/sqflite_porter.dart';

/// Copies [db] (schema, rows and version) to a new database file [name].
Future<Database> copyDatabase(Database db, String name) async {
  // SQL statements, no trailing ;
  var statements = await dbExportSql(db);
  var path = join(await getDatabasesPath(), name);
  // The import needs an empty database.
  await deleteDatabase(path);
  var copy = await openDatabase(path);
  await dbImportSql(copy, statements);
  return copy;
}
```

`dbExportSql` exports `PRAGMA user_version` (when not 0): the copy has the
version of `db`, reopening it with that version runs no `onCreate`.

## Migrating to sqflite_common_porter

Swap the dependency (`path: sqflite_common_porter`, `version: '>=0.3.0'`) and
the import (`package:sqflite_common_porter/sqflite_porter.dart`); the calls do
not change.
