import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite_dev.dart';
import 'package:sqflite_ffi_test/sqflite_ffi.dart';
import 'package:sqflite_test/sqflite_test.dart';

import 'server_all_test_.dart' as all;

var ffiTestContext =
    SqfliteLocalTestContext(databaseFactory: databaseFactoryFfi);

void main() {
  // Set sqflite ffi support in test
  //TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  setMockDatabaseFactory(databaseFactoryFfi);

  test('simplest', () async {
    var db = await openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
  //open.run(ffiTestContext);
  all.run(ffiTestContext);
}
