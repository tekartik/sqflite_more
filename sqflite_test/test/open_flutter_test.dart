import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show CachingAssetBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_test/sqflite_test.dart';
import 'package:test/test.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    //if (key == 'resources/test')
    print('## ${Directory.current}');
    return ByteData.view(
        Uint8List.fromList(await File(join(key)).readAsBytes()).buffer);
    // return null;
  }
}

Future main() {
  return testMain(run);
}

void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;

  test('Open asset database', () async {
    // await utils.devSetDebugModeOn(false);
    var rootBundle = TestAssetBundle();
    var databasesPath = await factory.getDatabasesPath();
    var path = join(databasesPath, 'asset_example.db');

    // delete existing if any
    await factory.deleteDatabase(path);

    // Copy from asset
    var data = await rootBundle.load(join('assets', 'example.db'));
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await context.writeFile(path, bytes);

    // open the database
    var db = await factory.openDatabase(path);

    // Our database as a single table with a single element
    var list = await db.rawQuery('SELECT * FROM Test');
    print('list $list');
    // list [{id: 1, name: simple value}]
    expect(list.first['name'], 'simple value');

    await db.close();
  }, skip: true);

  test('Open demo (doc)', () async {
    // await utils.devSetDebugModeOn(true);

    var path = await context.initDeleteDb('open_read_only.db');

    {
      Future _onConfigure(Database db) async {
        // Add support for cascade delete
        await db.execute('PRAGMA foreign_keys = ON');
      }

      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(onConfigure: _onConfigure));
      await db.close();
    }

    {
      Future _onCreate(Database db, int version) async {
        // Database is created, delete the table
        await db
            .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
      }

      Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
        // Database version is updated, alter the table
        await db.execute('ALTER TABLE Test ADD name TEXT');
      }

      // Special callback used for onDowngrade here to recreate the database
      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: _onCreate,
              onUpgrade: _onUpgrade,
              onDowngrade: onDatabaseDowngradeDelete));
      await db.close();
    }

    {
      Future _onOpen(Database db) async {
        // Database is open, print its version
        print('db version ${await db.getVersion()}');
      }

      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
            onOpen: _onOpen,
          ));
      await db.close();
    }
  });
  test('Open asset (doc)', () async {
    var rootBundle = TestAssetBundle();
    // asset (use existing copy if any)
    {
      // Check if we have an existing copy first
      var databasesPath = await factory.getDatabasesPath();
      var path = join(databasesPath, 'demo_asset_example.db');

      // try opening (will work if it exists)
      Database db;
      try {
        db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(readOnly: true));
      } catch (e) {
        print('Error $e');
      }

      if (db == null) {
        // Should happen only the first time you launch your application
        print('Creating new copy from asset');

        // Copy from asset
        var data = await rootBundle.load(join('assets', 'example.db'));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await context.writeFile(path, bytes);

        // open the database
        db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(readOnly: true));
      } else {
        print('Opening existing database');
      }

      await db.close();
    }
  }, skip: true);
}
