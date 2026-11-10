@TestOn('linux || windows')
library;

import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:sqflite_porter/src/utils.dart';
import 'package:sqflite_server_app/main.dart';

void main() {
  // The test menu (lib/test_main.dart) does not call run().
  test('database factory set without run(), as in the test menu', () async {
    var factory = databaseFactory;
    expect(factory, isNotNull);
    // The sqflite_porter helpers of the test menu use the sqflite default
    // factory (none set by the sqflite plugin on Linux and Windows).
    var path = await initEmptyDb('database_factory_test.db');
    var db = await factory!.openDatabase(path);
    try {
      await db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY)');
      expect(await db.query('test'), isEmpty);
    } finally {
      await db.close();
      await factory.deleteDatabase(path);
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}
