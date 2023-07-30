import 'dart:async';
import 'dart:typed_data';

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
    throw UnimplementedError();
  }

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions? options}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setDatabasesPath(String path) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readDatabaseBytes(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) {
    throw UnimplementedError();
  }
}

final databaseFactoryMock = DatabaseFactoryMock();
