// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';

/// Export a database to SQL statements, then restore it in a new one.
///
/// `dart run example/main.dart` (Dart VM, sqflite_common_ffi).
Future<void> main() async {
  sqfliteFfiInit();
  var factory = databaseFactoryFfi;
  var db = await factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Note (id INTEGER PRIMARY KEY, title TEXT)',
        );
      },
    ),
  );
  await db.insert('Note', {'title': 'Buy milk'});

  // Schema, rows and version as SQL statements (no trailing ;)
  var export = await dbExportSql(db);
  print(export);
  // [CREATE TABLE Note (id INTEGER PRIMARY KEY, title TEXT),
  //  INSERT INTO Note VALUES (1,'Buy milk'), PRAGMA user_version = 1]
  await db.close();

  // Deletes the database at the path, opens it and imports the statements
  var copy = await openDatabaseFromSqlImport(
    factory,
    inMemoryDatabasePath,
    export,
    openDatabaseOptions: OpenDatabaseOptions(singleInstance: false),
  );
  print(await copy.query('Note')); // [{id: 1, title: Buy milk}]
  await copy.close();
}
