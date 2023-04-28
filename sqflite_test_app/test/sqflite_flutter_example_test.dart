import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_test_app/src/sqflite_import.dart';

/// Initialize sqflite for test.
void sqfliteTestInit() {
  // Initialize ffi implementation
  sqfliteFfiInit();
  // Set global factory
  databaseFactory = databaseFactoryFfi;
}

Future main() async {
  sqfliteTestInit();
  test('simple', () async {
    var db = await openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE Product (
        id INTEGER PRIMARY KEY,
        title TEXT
      )
  ''');
    await db.insert('Product', <String, Object?>{'title': 'Product 1'});
    await db.insert('Product', <String, Object?>{'title': 'Product 2'});

    var result = await db.query('Product');
    expect(result, [
      {'id': 1, 'title': 'Product 1'},
      {'id': 2, 'title': 'Product 2'}
    ]);
    await db.close();
  });
}
