import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_test/sqflite_test.dart';

Future main() async {
  var context = await SqfliteServerTestContext.connect();
  if (context != null) {
    var factory = context.databaseFactory;
    test("Perf 100 insert", () async {
      String path = await context.initDeleteDb("slow_txn_100_insert.db");
      Database db = await factory.openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      await db.transaction((txn) async {
        for (int i = 0; i < 100; i++) {
          await txn.rawInsert(
              "INSERT INTO Test (name) VALUES (?)", <dynamic>["item $i"]);
        }
      });
      await db.close();
    });

    // Bigger timeout when using sqflite_server
    test("Perf 100 insert no txn", () async {
      String path = await context.initDeleteDb("slow_100_insert.db");
      Database db = await factory.openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");
      for (int i = 0; i < 1000; i++) {
        await db.rawInsert(
            "INSERT INTO Test (name) VALUES (?)", <dynamic>["item $i"]);
      }
      await db.close();
    }, timeout: Timeout(Duration(minutes: 2)));

    test("Perf 1000 insert", () async {
      String path = await context.initDeleteDb("slow_txn_1000_insert.db");
      Database db = await factory.openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Stopwatch sw = new Stopwatch()..start();
      await db.transaction((txn) async {
        for (int i = 0; i < 1000; i++) {
          await txn.rawInsert(
              "INSERT INTO Test (name) VALUES (?)", <dynamic>["item $i"]);
        }
      });
      print("1000 insert ${sw.elapsed}");
      await db.close();
    });

    test("Perf 1000 insert batch", () async {
      String path = await context.initDeleteDb("slow_txn_1000_insert_batch.db");
      Database db = await factory.openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Stopwatch sw = new Stopwatch()..start();
      Batch batch = db.batch();

      for (int i = 0; i < 1000; i++) {
        batch.rawInsert(
            "INSERT INTO Test (name) VALUES (?)", <dynamic>["item $i"]);
      }
      await batch.commit();
      print("1000 insert batch ${sw.elapsed}");
      await db.close();
    });

    test("Perf 1000 insert batch no result", () async {
      String path =
          await context.initDeleteDb("slow_txn_1000_insert_batch_no_result.db");
      Database db = await factory.openDatabase(path);
      await db.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)");

      Stopwatch sw = new Stopwatch()..start();
      Batch batch = db.batch();

      for (int i = 0; i < 1000; i++) {
        batch.rawInsert(
            "INSERT INTO Test (name) VALUES (?)", <dynamic>["item $i"]);
      }
      await batch.commit(noResult: true);

      print("1000 insert batch no result ${sw.elapsed}");
      await db.close();
    });
  }
}
