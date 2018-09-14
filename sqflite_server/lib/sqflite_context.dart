import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

abstract class SqfliteContext {
  DatabaseFactory get databaseFactory;
  Future<String> createDirectory(String path);
  Future<String> deleteDirectory(String path);
}

class _SqfliteContext implements SqfliteContext {
  @override
  DatabaseFactory get databaseFactory => sqflite.databaseFactory;

  @override
  Future<String> createDirectory(String path) async {
    try {
      path = await fixPath(path);
      await Directory(path).create(recursive: true);
    } catch (_e) {
      // print(e);
    }
    return path;
  }

  @override
  Future<String> deleteDirectory(String path) async {
    try {
      path = await fixPath(path);
      await Directory(path).delete(recursive: true);
    } catch (_e) {
      // print(e);
    }
    return path;
  }

  Future<String> fixPath(String path) async {
    if (path == null) {
      path = await databaseFactory.getDatabasesPath();
    } else if (path == inMemoryDatabasePath) {
      // nothing
    } else {
      if (isRelative(path)) {
        path = join(await databaseFactory.getDatabasesPath(), path);
      }
      path = absolute(normalize(path));
    }
    return path;
  }
}

SqfliteContext _sqfliteContext;
SqfliteContext get sqfliteContext => _sqfliteContext ??= _SqfliteContext();
