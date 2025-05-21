import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_test/sqflite_test.dart';

Future main() async {
  // Set sqflite ffi support in test
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  var server = await SqfliteServer.serve(factory: databaseFactoryFfi);
  var databaseFactory = await SqfliteServerDatabaseFactory.connect(server.url);
  var ffiClientTestContext = SqfliteLocalTestContext(
    databaseFactory: databaseFactory,
  );

  tearDownAll(() async {
    await server.close();
  });
  test('simplest', () async {
    var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
  all.run(ffiClientTestContext);
}
