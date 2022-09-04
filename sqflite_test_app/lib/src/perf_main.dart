// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:sqflite_test_app/src/import.dart';
import 'package:sqflite_test_app/src/sqflite_import.dart';

var sqfliteFactoryContext =
    PerfFactoryContext(name: 'sqflite', factory: sqflite.databaseFactory);
var sqfliteFfiFactoryContext = PerfFactoryContext(
    name: 'sqflite_ffi', factory: sqflite_ffi.databaseFactoryFfi);
var sqfliteFfiNoIsolateFactoryContext = PerfFactoryContext(
    name: 'sqflite_ffi (no isolate)',
    factory: sqflite_ffi.databaseFactoryFfiNoIsolate);

var factoryContexts = [
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
    sqfliteFactoryContext,
  sqfliteFfiFactoryContext,
  sqfliteFfiNoIsolateFactoryContext
];

var perfDbName = 'perf.db';

var ioDbNameContext = PerfDbNameContext(name: 'io', path: perfDbName);
var memoryDbNameContext =
    PerfDbNameContext(name: 'memory', path: inMemoryDatabasePath);
var dbNameContexts = [ioDbNameContext, memoryDbNameContext];

var perfContexts = dbNameContexts
    .map((d) => factoryContexts
        .map((f) => PerfContext(factoryContext: f, dbNameContext: d)))
    .expand((element) => element);

void perfMain() {
  menu('perf', () {
    item('bulkInsert', () async {
      var appDocDir = await getApplicationDocumentsDirectory();
      for (var perfContext in perfContexts) {
        await runBulkInsert(perfContext, appDocDir);
        await runBulkInsert(perfContext, appDocDir, noResult: true);
      }
    });
  });
}

Future<void> runBulkInsert(PerfContext perfContext, Directory directory,
    {bool? noResult}) async {
  var list = List.generate(
      13000,
      (index) => {
            'name': 'some name $index',
            'name2': 'some name $index',
            'name3': 'some name $index',
            'name4': 'some name $index'
          }).toList();
  write('$perfContext');
  var factory = perfContext.factory;
  var path = join(directory.path, perfContext.path);
  await factory.deleteDatabase(path);
  var db = await factory.openDatabase(path,
      options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
                'CREATE TABLE Test(id INTEGER PRIMARY KEY, name TEXT, name2 TEXT, name3 TEXT, name4 TEXT)');
          }));
  try {
    var sw = Stopwatch()..start();

    await db.transaction((txn) async {
      var batch = txn.batch();
      for (var rowData in list) {
        batch.insert('Test', rowData,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(continueOnError: false, noResult: noResult);
    });
    var elapsed = sw.elapsed;
    write('insert${noResult == true ? ' (noResult)' : ''}: $elapsed');
  } finally {
    await db.close();
  }
}

class PerfFactoryContext {
  final String name;
  final DatabaseFactory factory;

  PerfFactoryContext({required this.name, required this.factory});
}

class PerfDbNameContext {
  final String name;
  final String path;

  PerfDbNameContext({required this.name, required this.path});
}

class PerfContext {
  final PerfFactoryContext factoryContext;
  final PerfDbNameContext dbNameContext;

  DatabaseFactory get factory => factoryContext.factory;

  String get path => dbNameContext.name;

  PerfContext({required this.factoryContext, required this.dbNameContext});

  @override
  String toString() => '${factoryContext.name} ${dbNameContext.name}';
}
