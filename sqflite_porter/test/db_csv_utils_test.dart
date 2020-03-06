import 'dart:async';
import 'dart:convert';

import 'package:sqflite_porter/utils/csv_utils.dart';
import 'package:sqflite_test/sqflite_test.dart';
import 'package:test/test.dart';

import 'csv_utils_test.dart';

final String tableTodo = 'todo';
final String columnId = '_id';
final String columnTitle = 'title';
final String columnDone = 'done';

Future main() {
  return testMain(run);
}

void run(SqfliteServerTestContext context) {
  var factory = context.databaseFactory;

  test('csv', () async {
    var path = await context.initDeleteDb('csv_exp.db');
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
      var csv = mapListToCsv(result);
      expectCsv(csv, '''
id,name,value,num,binary
1,some name,1234,456.789,"[1, 2, 3]"
2,other name,1234,456.789,"[255, 254]"
''');
    } finally {
      await db?.close();
    }
  });
}
