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
      await db.insert('Product', <String, Object?>{'title': 'Product 1'});
      await db.insert('Product', <String, Object?>{'title': 'Product 2'});

      var results = await db.query('Product');
      expect(results, [
        {'id': 1, 'title': 'Product 1'},
        {'id': 2, 'title': 'Product 2'}
      ]);
      await db.close();
    });

    test('onCreate and batch', () async {
      var databaseFactory = databaseFactoryFfi;
      var db = await databaseFactory.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (db, version) async {
                var batch = db.batch();
                batch.execute('''
        CREATE TABLE Product (
            id INTEGER PRIMARY KEY,
            title TEXT
        )
        ''');
                batch
                    .insert('Product', <String, Object?>{'title': 'Product 1'});
                batch
                    .insert('Product', <String, Object?>{'title': 'Product 2'});
                var result = await batch.commit();
                expect(result.length, 3);
              }));
      var results = await db.query('Product');
      expect(results, [
        {'id': 1, 'title': 'Product 1'},
        {'id': 2, 'title': 'Product 2'}
      ]);
      await db.close();
    });
  });
}
