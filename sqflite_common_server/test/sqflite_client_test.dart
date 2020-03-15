import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:test/test.dart';

// This test only works when the app is running
Future main() async {
  var factory = await initSqfliteServerDatabaseFactory();

  tearDownAll(() async {
    await factory?.close();
  });

  group('client', () {
    test('init', () async {
      var db = await factory.openDatabase(inMemoryDatabasePath);
      try {
        expect(await db.getVersion(), 0);
      } finally {
        await db?.close();
      }

      // await sqfliteServer.close();
    });
  }, skip: factory == null);
}
