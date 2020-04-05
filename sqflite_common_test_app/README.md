# Simple sqlite test app

No flutter context needed.

## Setup

In `pubspec.yaml`:

```yaml
dependencies:
  sqflite_common:

dev_dependencies:
  sqflite_common_ffi:
```

# Simple app

Dart example file [example/main.dart](example/main.dart):

```dart
import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String jsonPretty(dynamic json) {
  return JsonEncoder.withIndent('  ').convert(json);
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
  await db.insert('Product', <String, dynamic>{'title': 'Product 1'});
  await db.insert('Product', <String, dynamic>{'title': 'Product 2'});

  var results = await db.query('Product');
  print(jsonPretty(results));
  // prints [{id: 1, title: Product 1}, {id: 2, title: Product 2}]
  await db.close();
}
```

# Simple test

Dart example test file [test/simple_test.dart](test/simple_test.dart):

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:test/test.dart';

Future main() async {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  group('db', () {
    test('simple', () async {
      var databaseFactory = databaseFactoryFfi;
      var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE Product (
            id INTEGER PRIMARY KEY,
            title TEXT
        )
        ''');
      print('adding 2 products...');
      await db.insert('Product', <String, dynamic>{'title': 'Product 1'});
      await db.insert('Product', <String, dynamic>{'title': 'Product 2'});

      var results = await db.query('Product');
      expect(results, [
        {'id': 1, 'title': 'Product 1'},
        {'id': 2, 'title': 'Product 2'}
      ]);
      await db.close();
    });
  });
}
```