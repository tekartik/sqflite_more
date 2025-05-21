// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_test_app/src/import.dart';

import 'asset_shared.dart';

Future<Uint8List> readAssetAsBytes(String name) async {
  var data = await rootBundle.load(url.join('assets', dbVersionNumName));
  return Uint8List.sublistView(data);
}

/// Copy the asset database if needed and open it.
///
/// It uses an external version file to keep track of the asset version.
Future<Database> copyIfNeededAndOpenAssetDatabase({
  required String databasesPath,
  required String versionNumFilename,
  required String dbFilename,
}) async {
  var dbPath = join(databasesPath, dbFilename);

  // First check the currently installed version
  var versionNumFile = File(join(databasesPath, versionNumFilename));
  var existingVersionNum = 0;
  if (versionNumFile.existsSync()) {
    existingVersionNum = int.parse(await versionNumFile.readAsString());
  }

  // Read the asset version
  var assetVersionNum = int.parse(
    await rootBundle.loadString(url.join('assets', versionNumFilename)),
  );

  // Compare them.
  print('existing/asset: $existingVersionNum/$assetVersionNum');

  // If needed, copy the asset database
  if (existingVersionNum < assetVersionNum) {
    print('copying new version $assetVersionNum');
    // Make sure the parent directory exists
    try {
      await Directory(databasesPath).create(recursive: true);
    } catch (_) {}

    // Copy from asset
    var data = await rootBundle.load(url.join('assets', dbFilename));
    var bytes = Uint8List.sublistView(data);

    // Write and flush the database bytes written
    await File(dbPath).writeAsBytes(bytes, flush: true);
    // Write and flush the version file
    await versionNumFile.writeAsString('$assetVersionNum', flush: true);
  }

  var db = await openDatabase(dbPath);
  return db;
}

void assetMain() {
  menu('perf', () {
    item('copy if needed and open asset database', () async {
      var db = await copyIfNeededAndOpenAssetDatabase(
        databasesPath: await getDatabasesPath(),
        // The asset database filename.
        dbFilename: 'my_asset_database.db',
        // The version num.
        versionNumFilename: 'db_version_num.txt',
      );

      write(await db.query('Value'));
      await db.close();
    });
  });
}
