// return the path
import 'dart:async';
import 'dart:core' as core;
import 'dart:core';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_porter/src/sql_parser.dart';
import 'package:sqflite_porter/src/sqlite_porter.dart';

Future<String> initEmptyDb(String dbName) async {
  var databasePath = await getDatabasesPath();
  // print(databasePath);
  String path = join(databasePath, dbName);

  // make sure the folder exists
  if (await Directory(dirname(path)).exists()) {
    await deleteDatabase(path);
  } else {
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (e) {
      print(e);
    }
  }
  return path;
}

Future<Database> openEmptyDatabase(String dbName) async {
  String path = await initEmptyDb(dbName);
  Database db = await openDatabase(path);
  return db;
}

Iterable<String> rowsToLines(Iterable<dynamic> rows) {
  return rows.map((dynamic row) => row?.toString());
}

String formatLines(List rows) {
  return '[${rowsToLines(rows).join(",\n")}]';
}

Function(dynamic message) _print = core.print;

void dumpSetPrint(Function(dynamic message) print) {
  _print = print;
}

void dumpLines(List rows, {Function(dynamic message) print}) {
  print ??= _print;
  rowsToLines(rows).toList().forEach((line) {
    print(line);
  });
}

void dumpLine(dynamic line, {Function(dynamic message) print}) {
  print ??= _print;
  print(line);
}

Future dumpTableDefinitions(Database db,
    {Function(dynamic message) print}) async {
  dumpLines(await db.query("sqlite_master"), print: print);
}

Future dumpTable(Database db, String table,
    {Function(dynamic message) print}) async {
  dumpLine('TABLE: $table', print: print);
  dumpLines(await db.query(table), print: print);
}

Future dumpTables(Database db, {Function(dynamic message) print}) async {
  for (var row in await db.query("sqlite_master", columns: ["name"])) {
    var table = row.values.first as String;
    await dumpTable(db, table, print: print);
  }
}

Future<Database> importSqlDatabase(String dbName,
    {String sql, List<String> sqlStatements}) async {
  sqlStatements ??= parseStatements(sql);
  if (sqlStatements == null) {
    throw ArgumentError('sql or sqlStatements is required');
  }
  String path = await initEmptyDb(dbName);
  Database db = await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
    await dbImportSql(db, sqlStatements);
  });
  return db;
}

String bookshelfSql = '''
CREATE TABLE book (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT);
INSERT INTO book(title) VALUES ('Le petit prince');
INSERT INTO book(title) VALUES ('Harry Potter');''';
