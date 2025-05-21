// return the path
import 'dart:core' as core;
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_porter/src/sql_parser.dart';
import 'package:sqflite_porter/src/sqlite_porter.dart';
export 'package:sqflite_common_porter/src/utils.dart';

Future<String> initEmptyDb(String dbName) async {
  var databasePath = await getDatabasesPath();
  // print(databasePath);
  var path = join(databasePath, dbName);

  // make sure the folder exists
  if (Directory(dirname(path)).existsSync()) {
    await deleteDatabase(path);
  } else {
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
  return path;
}

Future<Database> openEmptyDatabase(String dbName) async {
  var path = await initEmptyDb(dbName);
  var db = await openDatabase(path);
  return db;
}

Future<Database> importSqlDatabase(
  String dbName, {
  String? sql,
  List<String>? sqlStatements,
}) async {
  sqlStatements ??= parseStatements(sql);
  var path = await initEmptyDb(dbName);
  var db = await openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int version) async {
      await dbImportSql(db, sqlStatements!);
    },
  );
  return db;
}
