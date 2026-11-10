# sqflite_common_porter

Export a sqflite database to a list of SQL statements and import it back:
`dbExportSql` dumps the schema, the rows and the user version,
`dbImportSql` replays them into an empty database. Use it to back up,
duplicate or seed a database.

It works with any `sqflite_common` `DatabaseFactory`: `sqflite_common_ffi`
(Dart VM, desktop, tests), the `sqflite` plugin (Flutter Android, iOS, macOS),
`sqflite_ffi`, `sqflite_common_ffi_web` (web). A Flutter app using the
`sqflite` plugin can use the [sqflite_porter](../sqflite_porter) wrapper.

## Getting started

The package is not on pub.dev, add it as a git dependency:

```yaml
dependencies:
  sqflite_common_porter:
    git:
      url: https://github.com/tekartik/sqflite_more
      path: sqflite_common_porter
    version: '>=0.3.0'
```

Export a database, then restore it in a new one
([example/main.dart](example/main.dart), with `sqflite_common_ffi` on the Dart
VM):

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
        await db.execute(
          'CREATE TABLE Note (id INTEGER PRIMARY KEY, title TEXT)',
        );
      },
    ),
  );
  await db.insert('Note', {'title': 'Buy milk'});

  // Schema, rows and version as SQL statements (no trailing ;)
  var export = await dbExportSql(db);
  print(export);
  // [CREATE TABLE Note (id INTEGER PRIMARY KEY, title TEXT),
  //  INSERT INTO Note VALUES (1,'Buy milk'), PRAGMA user_version = 1]
  await db.close();

  // Deletes the database at the path, opens it and imports the statements
  var copy = await openDatabaseFromSqlImport(
    factory,
    inMemoryDatabasePath,
    export,
    openDatabaseOptions: OpenDatabaseOptions(singleInstance: false),
  );
  print(await copy.query('Note')); // [{id: 1, title: Buy milk}]
  await copy.close();
}
```

## API

| Function | Use it to |
|---|---|
| `dbExportSql(db)` | get the statements: `CREATE TABLE` and its rows table by table, then the indexes, views and triggers, `sqlite_sequence` and `PRAGMA user_version` (when not 0) |
| `dbImportSql(db, statements)` | replay them in an **empty** database (a `Batch`), for example in `onCreate` |
| `openDatabaseFromSqlImport(factory, path, statements)` | delete `path`, open it and import, in one call |
| `mapListToCsv`, `csvToMapList` | CSV helpers (`package:sqflite_common_porter/utils/csv_utils.dart`, from `tekartik_app_csv`) |

The statements are plain strings, store the list as JSON: do not join them
with `;` (a trigger contains `;`) nor with new lines (a `CREATE TABLE` keeps
the new lines it was written with).

## Common pitfalls

* `dbImportSql` needs an empty database: tables that already exist make the
  import fail. Use `openDatabaseFromSqlImport` or import in `onCreate`.
* With `inMemoryDatabasePath` pass `OpenDatabaseOptions(singleInstance: false)`,
  otherwise you get the database opened before.
* Virtual tables (fts, rtree) do not round trip: their internal tables are
  exported as plain tables and the import fails on them.
* Generated columns are not exported (their value is computed again), nor the
  `rowid` of a table without `INTEGER PRIMARY KEY`.
* `SqlImportOptions` (`importBatchSize`, several commits for a huge import)
  is not exported by `sqflite_porter.dart`.

The [package skill](skills/sqflite-common-porter-export-import/SKILL.md) has
more examples (copy to memory, seed in `onCreate`, CSV).
