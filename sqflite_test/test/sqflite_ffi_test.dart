import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_ffi_test/sqflite_ffi_test.dart';
import 'package:sqflite_test/sqflite_test.dart';

import 'all_test_.dart' as all;

class SqfliteFfiTestContext extends SqfliteServerTestContext {
  @override
  DatabaseFactory get databaseFactory => sqflite.databaseFactory;

  /// FFI no supports Without row id on linux
  @override
  bool get supportsWithoutRowId => false;
  @override
  bool get supportsDeadLock => false;

  /// FFI implementation is strict
  @override
  bool get strict => true;

  bool isInMemory(String path) {
    return path == sqflite.inMemoryDatabasePath;
  }

  Future<String> fixDirectoryPath(String path) async {
    if (path == null) {
      path = await databaseFactory.getDatabasesPath();
    } else {
      if (!isInMemory(path) && isRelative(path)) {
        path = join(await databaseFactory.getDatabasesPath(), path);
      }
    }
    return path;
  }

  @override
  Future<String> createDirectory(String path) async {
    path = await fixDirectoryPath(path);
    try {
      await Directory(path).create(recursive: true);
    } catch (_) {}
    return path;
  }

  @override
  Future<String> deleteDirectory(String path) async {
    path = await fixDirectoryPath(path);
    try {
      await Directory(path).delete(recursive: true);
    } catch (_) {}
    return path;
  }
}

var ffiTestContext = SqfliteFfiTestContext();

void main() {
  // Set sqflite ffi support in test
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiTestInit();

  test('simplest', () async {
    var db = await openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
  //open.run(ffiTestContext);
  all.run(ffiTestContext);
}
