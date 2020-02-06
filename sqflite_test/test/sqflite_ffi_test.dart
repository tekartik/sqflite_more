import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_ffi_test/sqflite_ffi_test.dart';
import 'package:sqflite_test/sqflite_test.dart';

import 'all_test_.dart' as all;

var ffiTestContext = SqfliteLocalTestContext();

void main() {
  // Set sqflite ffi support in test
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiTestInit();

  test('simplest', () async {
    var db = await openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
  //open.run(ffiTestContext);
  all.run(ffiTestContext);
}
