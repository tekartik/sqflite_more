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
