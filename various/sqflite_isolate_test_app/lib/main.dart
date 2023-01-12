// ignore_for_file: depend_on_referenced_packages

import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_test_menu_flutter/test_menu_flutter.dart';

void main() {
  Future<String> initDeleteDb(String path) async {
    path = join(await getDatabasesPath(), path);
    await deleteDatabase(path);
    return path;
  }

  mainMenu(() {
    //devPrint('MAIN_');
    // Sqflite.devSetDebugModeOn(true);

    item('Delete database', () async {
      var path = await initDeleteDb(isolateDbName);
      write('database $path deleted');
    });
    item('Create data in main', () async {
      var path = await initDeleteDb(isolateDbName);
      write(await simpleTest(path));
    });

    item('Create data in isolate', () async {
      write("starting isolate...don't expect any more information");
      var path = await initDeleteDb(isolateDbName);
      var receivePort = ReceivePort();
      var param = <String, Object?>{
        'sendPort': receivePort.sendPort,
        'path': path
      };
      await FlutterIsolate.spawn(simpleIsolate, param);

      var results = json.decode(await (receivePort.first as FutureOr<String>));
      write(results);
    });
    item('Read data', () async {
      var db = await openReadOnlyDatabase(isolateDbName);
      try {
        var results = await db.rawQuery('SELECT id, name FROM Test');
        write(results);
      } finally {
        await db.close();
      }
    });
  }, showConsole: true);
}

const isolateDbName = 'isolate.db';

Future insert(Database db, int id) async {
  await db.insert('Test', {'id': id, 'name': 'item $id'},
      conflictAlgorithm: ConflictAlgorithm.replace);
}

// Somehow it seems to expect a string for now...
void simpleIsolate(Map<String, Object?> param) {
  var path = param['path'] as String;
  var sendPort = param['sendPort'] as SendPort?;
  simpleTest(path).then((results) {
    // Convert result to string until I figure out how to have something else...
    sendPort!.send(json.encode(results));
  });
}

Future<List<Map<String, Object?>>> simpleTest(String path) async {
  // Get the path
  var db = await openDatabase(path, version: 1, onCreate: (db, version) {
    db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
  });
  List<Map<String, Object?>> results;
  try {
    await insert(db, 1);
    await insert(db, 2);
    await insert(db, 3);
    results = await db.rawQuery('SELECT id, name FROM Test');
    if (kDebugMode) {
      print(results);
    }
  } finally {
    await db.close();
  }
  return results;
}
