import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// ignore: implementation_imports
import 'package:sqflite_porter/src/utils.dart';
import 'package:sqflite_porter/sqflite_porter.dart';
import 'package:sqflite_server_app/main.dart';
import 'package:sqflite_server_app/src/app.dart';
import 'package:tekartik_test_menu_flutter/test.dart';
import 'package:sqflite_server_app/src/test/server_main.dart' as server;

void main() {
  mainMenu(() {
    dumpSetPrint(write);
    menu('run', () {
      item('go home', () {
        Navigator.of(buildContext).push<dynamic>(homePageRoute);
      });
      item('go home (restart app)', () async {
        //Sqflite.devSetDebugModeOn(true);
        await clearApp();
        await Navigator.of(buildContext).push<dynamic>(homePageRoute);
      });
      item('app', () {
        run();
      });
      server.main();
    });

    group('export/import', () {
      test('export_import', () async {
        var path = await initEmptyDb('export.db');
        var db = await openDatabase(path);
        try {
          var table = 'test';
          await db.execute(
              'CREATE TABLE $table (column_1 INTEGER, column_2 TEXT, column_3 BLOB)');
          await db.execute(
              'CREATE TABLE test_2 (id integer primary key autoincrement, column_2 TEXT)');
          // inserted in a wrong order to check ASC/DESC

          await db.execute('CREATE VIEW my_view AS SELECT * from $table');
          await db
              .execute("CREATE INDEX [${table}_index] ON '$table' (column_2)");
          await db.execute(
              'CREATE TRIGGER my_trigger AFTER INSERT ON test BEGIN INSERT INTO test_2(column_2) VALUES (new.column_2); END');

          await db.execute(
              'INSERT INTO $table (column_1, column_2, column_3) VALUES (11, ?, ?)',
              <dynamic>[
                'Some \' test \n',
                [1, 2, 3, 4]
              ]);
          var statements = await dbExportSql(db);
          var sql = statements.join('\n');
          write(sql);
          // print('#### $sql');
          expect(sql, '''
CREATE TABLE test (column_1 INTEGER, column_2 TEXT, column_3 BLOB);
INSERT INTO test VALUES (11,'Some '' test 
',x'01020304');
CREATE TABLE test_2 (id integer primary key autoincrement, column_2 TEXT);
INSERT INTO test_2 VALUES (1,'Some '' test 
');
DELETE FROM sqlite_sequence;
INSERT INTO sqlite_sequence VALUES ('test_2',1);
CREATE VIEW my_view AS SELECT * from test;
CREATE INDEX [test_index] ON 'test' (column_2);
CREATE TRIGGER my_trigger AFTER INSERT ON test BEGIN INSERT INTO test_2(column_2) VALUES (new.column_2); END;''');

          // print('#### $sql');
          await db.close();
          db = await openEmptyDatabase('import.db');
          await dbImportSql(db, statements);
          // re-export
          var statements2 = await dbExportSql(db);
          expect(statements2, statements);
        } finally {
          await db.close();
        }
      });
    });

    var bookshelfSql = '''
CREATE TABLE book (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT);
INSERT INTO book(title) VALUES ('Le petit prince');
INSERT INTO book(title) VALUES ('Harry Potter');
''';

    group('meta', () {
      test('table_definitions', () async {
        //Sqflite.devSetDebugModeOn(true);
        var db = await importSqlDatabase('book_table_definitions.db',
            sql: bookshelfSql);
        try {
          await dumpTableDefinitions(db);
          // print(await db.query('sqlite_master'));} finally {
        } finally {
          await db.close();
        }
      });

      test('table', () async {
        //Sqflite.devSetDebugModeOn(true);
        var db =
            await importSqlDatabase('book_dump_table.db', sql: bookshelfSql);
        try {
          await dumpTable(db, 'book');
        } finally {
          await db.close();
        }
      });

      test('tables', () async {
        //Sqflite.devSetDebugModeOn(true);
        var db =
            await importSqlDatabase('book_dump_tables.db', sql: bookshelfSql);
        try {
          await dumpTables(db);
        } finally {
          await db.close();
        }
      });
    });
  });
}
