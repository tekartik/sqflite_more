import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_ffi_test/sqflite_ffi_test.dart';

void main() {
  // Set sqflite ffi support in test
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiTestInit();

  test('Issue#384', () async {
    var db = await openDatabase(inMemoryDatabasePath);
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
    }
  });
}
