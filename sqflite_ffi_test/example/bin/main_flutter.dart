import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_ffi_test/sqflite_ffi.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi;
  var db = await databaseFactory.openDatabase(inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1));
  expect(await db.getVersion(), 1);
  await db.close();

  db = await databaseFactory.openDatabase('simple_version_1.db',
      options: OpenDatabaseOptions(version: 1));
  expect(await db.getVersion(), 1);
  await db.close();
}
