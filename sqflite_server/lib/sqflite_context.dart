import 'dart:async';

import 'package:sqflite/sqlite_api.dart';
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
