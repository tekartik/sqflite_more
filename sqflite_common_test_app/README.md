# sqflite_common_test_app

A minimal Dart program and unit test using the sqflite API without Flutter,
through [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi)
(SQLite in the Dart VM, Linux, macOS and Windows). Copy it to start a command
line tool, or the tests of a package that uses sqflite.

## Setup

```bash
dart pub add sqflite_common_ffi
dart pub add dev:test
```

`package:sqflite_common_ffi/sqflite_ffi.dart` exports the whole sqflite API
(`Database`, `OpenDatabaseOptions`, `inMemoryDatabasePath`...), no other
import is needed. SQLite is bundled by the `sqlite3` build hooks, which run
with `dart run` and `dart test` (not with `dart file.dart`).

## Program

[example/main.dart](example/main.dart), run it with
`dart run example/main.dart`:

```dart
import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String jsonPretty(Object? json) {
  return const JsonEncoder.withIndent('  ').convert(json);
}

Future main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi;
  var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
  await db.execute('''
  CREATE TABLE Product (
      id INTEGER PRIMARY KEY,
      title TEXT
  )
  ''');
  print('adding 2 products...');
  await db.insert('Product', <String, Object?>{'title': 'Product 1'});
  await db.insert('Product', <String, Object?>{'title': 'Product 2'});

  var results = await db.query('Product');
  print(jsonPretty(results));
  // prints [{id: 1, title: Product 1}, {id: 2, title: Product 2}]
  await db.close();
}
```

An in memory database (`inMemoryDatabasePath`) is gone once closed. For a
file, give a path: a relative one is in `databaseFactory.getDatabasesPath()`
(`.dart_tool/sqflite_common_ffi/databases` of the current directory).

## Test

[test/simple_test.dart](test/simple_test.dart) runs the same code in a test,
and a second test creating the table and its rows in `onCreate` with a batch:

```bash
dart test
```
