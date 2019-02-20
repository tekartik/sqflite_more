import 'dart:async';

import 'package:sqflite/sqlite_api.dart';

class DatabaseFactoryMock implements DatabaseFactory {
  @override
  Future<bool> databaseExists(String path) async {
    return false;
  }

  @override
  Future<void> deleteDatabase(String path) async {}

  @override
  Future<String> getDatabasesPath() async {
    return null;
  }

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions options}) {
    return null;
  }
}

final databaseFactoryMock = DatabaseFactoryMock();
