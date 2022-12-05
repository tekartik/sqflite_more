# sqflite_common_porter

Sqflite importer/exporter.
**Warning**: this is just some reference code.
* version is now exported (since v)
* trigger/view not tested yet.

## Getting Started

Following [versioning doc](https://github.com/tekartik/common.dart/blob/main/doc/tekartik_versioning.md), add in pubspec.yaml:

````yaml
dependencies:
  sqflite_common_porter:
    git:
      url: https://github.com/tekartik/sqflite_more
      ref: dart2_3
      path: sqflite_common_porter
    version: '>=0.2.0'
````

## Usage

Exporting

```dart
import 'package:sqflite_common_porter/sqflite_porter.dart';

var export = await dbExportSql(db);
```

Importing (open an empty database)

```dart
import 'package:sqflite_common_porter/sqflite_porter.dart';

var export = await dbExportSql(db);
```
You can also import during `onCreate`:

```dart
// Import during onCreate
db = await factory.openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(version: 1, onCreate: (db, _) async {
  await dbImportSql(db, export);
}));
```