import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Set sqflite ffi support in test
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  var factory = databaseFactoryFfi;

  test('Issue#384', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE test (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE NOT NULL
      )''');
    try {
      var batch = db.batch();
      for (var obj in [
        {'name': 'name1'},
        {'name': 'name1'}
      ]) {
        batch.insert('Test', obj);
      }
      await batch.commit();
      fail('should fail');
    } on DatabaseException catch (e) {
      print('error: $e');
    } finally {
      await db.close();
    }
  });

  test('Issue#402', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath);
    try {
      await db.execute('''
      CREATE TABLE test (
        name TEXT PRIMARY KEY
      )''');
      var key1 = await db.insert('test', {'name': 'name 1'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      var key2 = await db.insert('test', {'name': 'name 2'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      // Conflict
      var key3 = await db.insert('test', {'name': 'name 1'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      expect([key1, key2, key3], [1, 2, 0]);
    } finally {
      await db.close();
    }
  });
}
