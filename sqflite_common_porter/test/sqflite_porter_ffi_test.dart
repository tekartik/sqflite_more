@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';
import 'package:test/test.dart';

Future<Database> openDatabaseInMemoryFromSqlImport(
  DatabaseFactory factory,
  List<String> export,
) async {
  var db = await openDatabaseFromSqlImport(
    factory,
    inMemoryDatabasePath,
    export,
    openDatabaseOptions: OpenDatabaseOptions(singleInstance: false),
  );
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
        version: 2,
        onCreate: (db, version) async {},
        singleInstance: false,
      ),
    );
    var export = await dbExportSql(db);
    expect(export, ['PRAGMA user_version = 2']);
    await db.close();

    db = await openDatabaseInMemoryFromSqlImport(factory, export);
    expect(await db.getVersion(), 2);
    await db.close();
  });
  test('export simple', () async {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)',
          );
        },
      ),
    );
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
      {'id': 1, 'value': 'my_value'},
    ]);

    await db.close();
  });
  test('export view', () async {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)',
          );
          await db.execute('CREATE VIEW TestView AS SELECT value FROM Test');
        },
      ),
    );
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
      {'value': 'my_value'},
    ]);

    await db.close();
  });
  test('export trigger', () async {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)',
          );
          await db.execute('CREATE TABLE TestCopy (value TEXT)');
          await db.execute(
            'CREATE TRIGGER Copy AFTER INSERT ON Test BEGIN INSERT INTO TestCopy(value) VALUES(NEW.value); END',
          );
        },
      ),
    );
    Future<void> checkContent() async {
      // Check content
      expect(await db.query('Test'), [
        {'id': 1, 'value': 'my_value'},
      ]);
      expect(await db.query('TestCopy'), [
        {'value': 'my_value'},
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
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, textValue TEXT, integerValue INTEGER, realValue REAL, blobValue BLOB)',
          );
        },
      ),
    );
    // Insert some data
    await db.insert('Test', {
      'textValue': 'with_accent_éà',
      'integerValue': 1234,
      'realValue': 1.5,
      'blobValue': Uint8List.fromList([1, 2, 3]),
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
        'blobValue': Uint8List.fromList([1, 2, 3]),
      },
    ]);

    await db.close();
  });
  test('export auto increment', () async {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT)',
          );
        },
      ),
    );
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
      {'id': 1, 'value': 'my_value'},
    ]);

    await db.close();
  });
  test('import in onCreate', () async {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT)',
          );
        },
      ),
    );
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    var export = await dbExportSql(db);
    await db.close();

    // Import during onCreate
    db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        singleInstance: false,
        version: 1,
        onCreate: (db, _) async {
          await dbImportSql(db, export);
        },
      ),
    );

    // Check content
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'},
    ]);

    await db.close();
  });
  group('table names', () {
    // Table name in the create statement and its expected name in the export
    var names = {
      '"group"': '"group"',
      '"my table"': '"my table"',
      '`back`': '`back`',
      '[my table2]': '"my table2"',
    };
    names.forEach((name, sqlName) {
      test('export import $name', () async {
        var db = await factory.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false),
        );
        await db.execute(
          'CREATE TABLE $name (id INTEGER PRIMARY KEY, value TEXT)',
        );
        await db.execute("INSERT INTO $name (value) VALUES ('v1')");
        var export = await dbExportSql(db);
        expect(export, [
          'CREATE TABLE $name (id INTEGER PRIMARY KEY, value TEXT)',
          'INSERT INTO $sqlName VALUES (1,\'v1\')',
        ]);
        await db.close();

        db = await openDatabaseInMemoryFromSqlImport(factory, export);
        expect(await db.rawQuery('SELECT * FROM $name'), [
          {'id': 1, 'value': 'v1'},
        ]);
        await db.close();
      });
    });
  });
  test('export virtual table once', () async {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute(
      'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT)',
    );
    await db.execute('CREATE VIRTUAL TABLE r USING rtree(id, minX, maxX)');
    var export = await dbExportSql(db);
    expect(export.where((sql) => sql.startsWith('CREATE VIRTUAL TABLE')), [
      'CREATE VIRTUAL TABLE r USING rtree(id, minX, maxX)',
    ]);
    await db.close();
  });
  test('export generated columns', () async {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute(
      'CREATE TABLE "my test" (a INTEGER, c INTEGER GENERATED ALWAYS AS (a * 2) STORED, b TEXT, d TEXT AS (b || \'!\'))',
    );
    await db.execute('CREATE TABLE Other (id INTEGER PRIMARY KEY, value TEXT)');
    await db.execute('INSERT INTO "my test" (a, b) VALUES (1, \'x\')');
    await db.insert('Other', {'value': 'v'});
    var export = await dbExportSql(db);
    // Only the non generated columns get a value, other tables unchanged.
    expect(export, [
      'CREATE TABLE "my test" (a INTEGER, c INTEGER GENERATED ALWAYS AS (a * 2) STORED, b TEXT, d TEXT AS (b || \'!\'))',
      'INSERT INTO "my test" VALUES (1,\'x\')',
      'CREATE TABLE Other (id INTEGER PRIMARY KEY, value TEXT)',
      'INSERT INTO Other VALUES (1,\'v\')',
    ]);
    await db.close();

    db = await openDatabaseInMemoryFromSqlImport(factory, export);
    expect(await db.rawQuery('SELECT * FROM "my test"'), [
      {'a': 1, 'c': 2, 'b': 'x', 'd': 'x!'},
    ]);
    await db.close();
  });
  test('export infinite values', () async {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value REAL)');
    for (var value in [double.infinity, double.negativeInfinity, 1.5]) {
      await db.insert('Test', {'value': value});
    }
    var export = await dbExportSql(db);
    expect(export.skip(1), [
      'INSERT INTO Test VALUES (1,9e999)',
      'INSERT INTO Test VALUES (2,-9e999)',
      'INSERT INTO Test VALUES (3,1.5)',
    ]);
    await db.close();

    db = await openDatabaseInMemoryFromSqlImport(factory, export);
    expect(await db.query('Test'), [
      {'id': 1, 'value': double.infinity},
      {'id': 2, 'value': double.negativeInfinity},
      {'id': 3, 'value': 1.5},
    ]);
    await db.close();
  });
}
