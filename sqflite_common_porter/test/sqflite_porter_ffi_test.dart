@TestOn('vm')
library sqflite_common_porter.ffi_test;

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';
import 'package:test/test.dart';

void main() {
  var factory = databaseFactoryFfi;

  // Init ffi loader if needed.
  sqfliteFfiInit();
  test('export empty', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath);
    expect(await dbExportSql(db), []);

    await db.close();
  });
  test('export simple', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
            }));
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    var export = await dbExportSql(db);
    expect(export, [
      'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT);',
      'INSERT INTO Test VALUES (1,\'my_value\');'
    ]);
    await db.close();

    // Import
    db = await factory.openDatabase(inMemoryDatabasePath);
    await dbImportSql(db, export);
    // Check content
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'}
    ]);

    await db.close();
  });
  test('export auto increment', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT)');
            }));
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    var export = await dbExportSql(db);
    expect(export, [
      'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT);',
      'INSERT INTO Test VALUES (1,\'my_value\');',
      'DELETE FROM sqlite_sequence;',
      'INSERT INTO sqlite_sequence VALUES (\'Test\',1);'
    ]);
    await db.close();

    // Import
    db = await factory.openDatabase(inMemoryDatabasePath);
    await dbImportSql(db, export);
    // Check content
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'}
    ]);

    await db.close();
  });
  test('import in onCreate', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT)');
            }));
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    var export = await dbExportSql(db);
    await db.close();

    // Import during onCreate
    db = await factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              await dbImportSql(db, export);
            }));

    // Check content
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'}
    ]);

    await db.close();
  });
}
