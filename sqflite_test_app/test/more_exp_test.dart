import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_test/sqflite_test.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    //if (key == 'resources/test')
    return ByteData.view(
        Uint8List.fromList(await File(key).readAsBytes()).buffer);
    // return null;
  }
}

Future main() async {
  var context = await SqfliteServerTestContext.connect();
  if (context != null) {
    var factory = context.databaseFactory;

    test("Issue#144", () async {
      /*

      initDb() async {
        String databases_path = await getDatabasesPath();
        String path = join(databases_path, 'example.db');

        print(FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.notFound); // false
        Database oldDB = await openDatabase(path);
        List count = await oldDB.rawQuery(
            "select 'name' from sqlite_master where name = 'example_table'");
        print(count.length); // 0

        print('copy from asset');
        await deleteDatabase(path);
        print(FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.notFound); // true
        ByteData data =
            await rootBundle.load(join("assets", 'example.db')); // 6,9 MB

        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes);
        Database db = await openDatabase(path);
        print(FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.notFound); // false
        List count2 = await db.rawQuery(
            "select 'name' from sqlite_master where name = 'example_table'");
        print(count2.length); // 0 should 1

        return db; // should
      }

       */
      // Sqflite.devSetDebugModeOn(true);
      // Try to insert string with quote
      String path = await context.initDeleteDb("exp_issue_144.db");
      var rootBundle = TestAssetBundle();
      Database db;
      print('current dir: ${absolute(Directory.current.path)}');
      print('path: $path');
      try {
        Future<Database> initDb() async {
          Database oldDB = await factory.openDatabase(path);
          List count = await oldDB
              .rawQuery("select 'name' from sqlite_master where name = 'Test'");
          print(count.length); // 0

          // IMPORTANT! Close the database before deleting it
          await oldDB.close();

          print('copy from asset');
          await factory.deleteDatabase(path);
          ByteData data = await rootBundle.load(join("assets", 'example.db'));

          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          //print(bytes);
          expect(bytes.length, greaterThan(1000));
          // Writing the database
          await context.writeFile(path, bytes);
          Database db = await factory.openDatabase(path,
              options: OpenDatabaseOptions(readOnly: true));
          List count2 = await db
              .rawQuery("select 'name' from sqlite_master where name = 'Test'");
          print(count2);

          // Our database as a single table with a single element
          List<Map<String, dynamic>> list =
              await db.rawQuery("SELECT * FROM Test");
          print("list $list");
          // list [{id: 1, name: simple value}]
          expect(list.first["name"], "simple value");

          return db; // should
        }

        db = await initDb();
      } finally {
        await db?.close();
      }
    });
  }
}
