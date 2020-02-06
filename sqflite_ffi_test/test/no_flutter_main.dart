import 'dart:async';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_ffi_test/sqflite_ffi.dart';

Future<void> main() async {
  var databaseFactory = databaseFactoryFfi;
  var db = await databaseFactory.openDatabase(inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1, singleInstance: true));
  var version = await db.getVersion();
  // print('Opened $db version $version');
  assert(version == 1, 'Bad version $version');
}
