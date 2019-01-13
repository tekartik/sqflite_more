import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;

abstract class SqfliteContext {
  DatabaseFactory get databaseFactory;
  Future<String> createDirectory(String path);
  Future<String> deleteDirectory(String path);
  Future<String> writeFile(String path, List<int> data);
  Future<List<int>> readFile(String path);
  bool get supportsWithoutRowId;
  bool get isAndroid;
  bool get isIOS;
  path.Context get pathContext;
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
        path = pathContext.join(await databaseFactory.getDatabasesPath(), path);
      }
      path = pathContext.absolute(pathContext.normalize(path));
    }
    return path;
  }

  @override
  bool get supportsWithoutRowId => !Platform.isIOS;

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;

  @override
  Context get pathContext => path.context;

  @override
  Future<List<int>> readFile(String path) async =>
      File(await fixPath(path)).readAsBytes();

  @override
  Future<String> writeFile(String path, List<int> data) async {
    path = await fixPath(path);
    await File(await fixPath(path)).writeAsBytes(data, flush: true);
    return path;
  }
}

SqfliteContext _sqfliteContext;
SqfliteContext get sqfliteContext => _sqfliteContext ??= _SqfliteContext();
