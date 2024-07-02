import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_test_app/src/asset_shared.dart';

Future<void> main() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  var dbPath = normalize(absolute(join('assets', dbName)));
  var dbVersionNumPath = join('assets', dbVersionNumName);

  var versionNum = 0;
  var file = File(dbVersionNumPath);
  if (file.existsSync()) {
    versionNum = int.parse(await File(dbVersionNumPath).readAsString());
    print('versionNum: $versionNum');
  } else {
    print('versionNum file not found');
  }
  versionNum++;

  var db = await databaseFactoryFfi.openDatabase(dbPath,
      options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
                'CREATE TABLE Value (id INTEGER PRIMARY KEY, value INTEGER)');
          }));
  await db.insert('Value', {'id': 1, 'value': versionNum},
      conflictAlgorithm: ConflictAlgorithm.replace);
  await db.close();
  await file.writeAsString('$versionNum');
}
