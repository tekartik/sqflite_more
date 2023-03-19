@TestOn('vm')
library sqflite_common_porter.ffi_test;

import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';
import 'package:test/test.dart';

Future<Database> openDatabaseInMemoryFromSqlImport(
    DatabaseFactory factory, List<String> export) async {
  var db =
      await openDatabaseFromSqlImport(factory, inMemoryDatabasePath, export,
          openDatabaseOptions: OpenDatabaseOptions(
            singleInstance: false,
          ));
  return db;
}

void main() {
  var factory = databaseFactoryFfi;

  // Init ffi loader if needed.
  sqfliteFfiInit();
  // factory.debugSetLogLevel(sqfliteLogLevelVerbose);
  test('export empty', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath);
    var export = await dbExportSql(db);
    expect(export, isEmpty);

    await db.close();
    db = await openDatabaseInMemoryFromSqlImport(factory, export);
    expect(await db.getVersion(), 0);
    await db.close();
  });
  test('export version import', () async {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
          version: 2, onCreate: (db, version) async {}, singleInstance: false),
    );
    var export = await dbExportSql(db);
    expect(export, ['PRAGMA user_version = 2']);
    print(export);
    await db.close();

    db = await openDatabaseInMemoryFromSqlImport(factory, export);
    expect(await db.getVersion(), 2);
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
      'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)',
      'INSERT INTO Test VALUES (1,\'my_value\')',
      'PRAGMA user_version = 1',
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
  test('export view', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
              await db
                  .execute('CREATE VIEW TestView AS SELECT value FROM Test');
            }));
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    var export = await dbExportSql(db);
    expect(export, [
      'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)',
      'INSERT INTO Test VALUES (1,\'my_value\')',
      'CREATE VIEW TestView AS SELECT value FROM Test',
      'PRAGMA user_version = 1',
    ]);
    await db.close();

    // Import
    db = await openDatabaseInMemoryFromSqlImport(factory, export);
    // Check content
    expect(await db.query('TestView'), [
      {'value': 'my_value'}
    ]);

    await db.close();
  });
  test('export trigger', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
              await db.execute('CREATE TABLE TestCopy (value TEXT)');
              await db.execute(
                  'CREATE TRIGGER Copy AFTER INSERT ON Test BEGIN INSERT INTO TestCopy(value) VALUES(NEW.value); END');
            }));
    Future<void> checkContent() async {
      // Check content
      expect(await db.query('Test'), [
        {'id': 1, 'value': 'my_value'}
      ]);
      expect(await db.query('TestCopy'), [
        {'value': 'my_value'}
      ]);
    }

    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    await checkContent();
    var export = await dbExportSql(db);
    expect(export, [
      'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)',
      'INSERT INTO Test VALUES (1,\'my_value\')',
      'CREATE TABLE TestCopy (value TEXT)',
      'INSERT INTO TestCopy VALUES (\'my_value\')',
      'CREATE TRIGGER Copy AFTER INSERT ON Test BEGIN INSERT INTO TestCopy(value) VALUES(NEW.value); END',
      'PRAGMA user_version = 1',
    ]);
    await db.close();

    // Import
    db = await openDatabaseInMemoryFromSqlImport(factory, export);
    await checkContent();

    await db.close();
  });
  test('all types simple', () async {
    var db = await factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE Test (id INTEGER PRIMARY KEY, textValue TEXT, integerValue INTEGER, realValue REAL, blobValue BLOB)');
            }));
    // Insert some data
    await db.insert('Test', {
      'textValue': 'with_accent_éà',
      'integerValue': 1234,
      'realValue': 1.5,
      'blobValue': Uint8List.fromList([1, 2, 3])
    });

    var export = await dbExportSql(db);
    expect(export, [
      'CREATE TABLE Test (id INTEGER PRIMARY KEY, textValue TEXT, integerValue INTEGER, realValue REAL, blobValue BLOB)',
      'INSERT INTO Test VALUES (1,\'with_accent_éà\',1234,1.5,x\'010203\')',
      'PRAGMA user_version = 1',
    ]);
    await db.close();

    // Import
    db = await openDatabaseInMemoryFromSqlImport(factory, export);
    // Check content
    expect(await db.query('Test'), [
      {
        'id': 1,
        'textValue': 'with_accent_éà',
        'integerValue': 1234,
        'realValue': 1.5,
        'blobValue': Uint8List.fromList([1, 2, 3])
      }
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
      'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT)',
      'INSERT INTO Test VALUES (1,\'my_value\')',
      'DELETE FROM sqlite_sequence',
      'INSERT INTO sqlite_sequence VALUES (\'Test\',1)',
      'PRAGMA user_version = 1',
    ]);
    await db.close();

    // Import
    db = await openDatabaseInMemoryFromSqlImport(factory, export);
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
            singleInstance: false,
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
