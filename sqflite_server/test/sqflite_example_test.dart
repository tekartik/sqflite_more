import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_server/sqflite.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:test/test.dart';

void main() {
  group('example', () {
    SqfliteServerDatabaseFactory databaseFactory;
    setUpAll(() async {
      databaseFactory = await initSqfliteServerDatabaseFactory();
    });

    tearDownAll(() async {
      await databaseFactory?.close();
    });

    test('simple', () async {
      // Always test if the factory is available before each test
      if (databaseFactory != null) {
        var path = join(await databaseFactory.getDatabasesPath(),
            'sqlite_server_example.db');
        await databaseFactory.deleteDatabase(path);

        var database = await databaseFactory.openDatabase(path,
            options: OpenDatabaseOptions(version: 1));
        expect(await database.getVersion(), 1);

        await database.execute(
            "CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)");
        print("table created");
        int id = await database.rawInsert(
            'INSERT INTO Test(name, value, num) VALUES("some name",1234,?)',
            <dynamic>[456.789]);
        print("inserted1: $id");
        id = await database.rawInsert(
            'INSERT INTO Test(name, value) VALUES(?, ?)',
            <dynamic>["another name", 12345678]);
        print("inserted2: $id");
        int count = await database.rawUpdate(
            'UPDATE Test SET name = ?, VALUE = ? WHERE name = ?',
            <dynamic>["updated name", "9876", "some name"]);
        print("updated: $count");
        expect(count, 1);
        List<Map> list = await database.rawQuery('SELECT * FROM Test');
        List<Map> expectedList = [
          <String, dynamic>{
            "name": "updated name",
            "id": 1,
            "value": 9876,
            "num": 456.789
          },
          <String, dynamic>{
            "name": "another name",
            "id": 2,
            "value": 12345678,
            "num": null
          }
        ];

        print("list: ${json.encode(list)}");
        //print("expected $expectedList");
        expect(list, expectedList);
        await database.close();
      }
    });
  });
}
