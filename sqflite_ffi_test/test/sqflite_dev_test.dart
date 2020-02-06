import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_ffi_test/sqflite_ffi_test.dart';
import 'package:sqflite_ffi_test/sqflite_dev.dart';

void main() {
  // Set sqflite ffi support in test
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiTestInit();

  test('simple sqflite example', () async {
    var db = await openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();

    // ignore: deprecated_member_use_from_same_package
    await databaseFactory.setDebugModeOn(true);
    db = await openDatabase(inMemoryDatabasePath, version: 1);
    expect(await db.getVersion(), 1);
    await db.close();
    // ignore: deprecated_member_use_from_same_package
    await databaseFactory.setDebugModeOn(false);

    db = await openDatabase('simple_version_1.db', version: 1);
    expect(await db.getVersion(), 1);
    await db.close();
  });
}
