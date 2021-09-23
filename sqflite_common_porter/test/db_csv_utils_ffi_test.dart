import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_porter/src/utils.dart';
import 'package:sqflite_common_porter/utils/csv_utils.dart';
import 'package:test/test.dart';

import 'csv_utils_test.dart';

final String tableTodo = 'todo';
final String columnId = '_id';
final String columnTitle = 'title';
final String columnDone = 'done';

void main() {
  var factory = databaseFactoryFfi;

  // Init ffi loader if needed.
  sqfliteFfiInit();

  test('csv', () async {
    var path = await initDeleteDb(factory, 'csv_exp.db');
    var db = await factory.openDatabase(path);
    try {
      var sql = '''
CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL, binary BLOB)
INSERT INTO Test(name, value, num, binary) VALUES('some name', 1234, 456.789, x'010203')
INSERT INTO Test(name, value, num, binary) VALUES('other name', 1234, 456.789, x'FFFE')
''';

      var batch = db.batch();
      const LineSplitter().convert(sql).forEach((cmd) {
        batch.execute(cmd);
      });
      await batch.commit();

      var result = await db.query('Test');
      var csv = mapListToCsv(result)!;
      expectCsv(csv, '''
id,name,value,num,binary
1,some name,1234,456.789,"[1, 2, 3]"
2,other name,1234,456.789,"[255, 254]"
''');
    } finally {
      await db.close();
    }
  });
}
