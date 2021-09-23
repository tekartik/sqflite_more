// return the path
import 'dart:async';
import 'dart:core' as core;
import 'dart:core';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_porter/src/sql_parser.dart';
import 'package:sqflite_common_porter/src/sqlite_porter.dart';

Future<String> initDeleteDb(DatabaseFactory factory, String dbName) async {
  var databasePath = await factory.getDatabasesPath();
  // print(databasePath);
  var path = join(databasePath, dbName);

  // make sure the folder exists
  if (Directory(dirname(path)).existsSync()) {
    await factory.deleteDatabase(path);
  } else {
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (e) {
      print(e);
    }
  }
  return path;
}

Future<Database> openEmptyDatabase(
    DatabaseFactory factory, String dbName) async {
  var path = await initDeleteDb(factory, dbName);
  var db = await factory.openDatabase(path);
  return db;
}

Iterable<String> rowsToLines(Iterable<Object?> rows) {
  return rows.map((Object? row) => row.toString());
}

String formatLines(List rows) {
  return '[${rowsToLines(rows).join(',\n')}]';
}

Function(Object? message) _print = core.print;

void dumpSetPrint(Function(Object? message) print) {
  _print = print;
}

void dumpLines(List rows, {Function(Object? message)? print}) {
  print ??= _print;
  rowsToLines(rows).toList().forEach((line) {
    print!(line);
  });
}

void dumpLine(Object? line, {Function(Object? message)? print}) {
  print ??= _print;
  print(line);
}

Future dumpTableDefinitions(Database db,
    {Function(Object? message)? print}) async {
  dumpLines(await db.query('sqlite_master'), print: print);
}

Future dumpTable(Database db, String table,
    {Function(Object? message)? print}) async {
  dumpLine('TABLE: $table', print: print);
  dumpLines(await db.query(table), print: print);
}

Future dumpTables(Database db, {Function(Object? message)? print}) async {
  for (var row in await db.query('sqlite_master', columns: ['name'])) {
    var table = row.values.first as String;
    await dumpTable(db, table, print: print);
  }
}

Future<Database> importSqlDatabase(DatabaseFactory factory, String dbName,
    {String? sql, List<String>? sqlStatements}) async {
  sqlStatements ??= parseStatements(sql);
  var path = await initDeleteDb(factory, dbName);
  var db = await factory.openDatabase(path,
      options: OpenDatabaseOptions(
          version: 1,
          onCreate: (Database db, int version) async {
            await dbImportSql(db, sqlStatements!);
          }));
  return db;
}

String bookshelfSql = '''
CREATE TABLE book (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT);
INSERT INTO book(title) VALUES ('Le petit prince');
INSERT INTO book(title) VALUES ('Harry Potter');''';
