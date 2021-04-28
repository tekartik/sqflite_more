import 'dart:async';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/utils/utils.dart' as utils;
import 'package:sqflite_porter/src/sql_parser.dart';

String fixStatement(String sql) {
  if (!sql.endsWith(';')) {
    return '$sql;';
  }
  return sql;
}

String sanitizeText(String text) {
  return text.replaceAll("'", "''");
}

bool isSystemTable(String table) {
  return table.startsWith('sqlite_') || table == 'android_metadata';
}

String? extractTableName(String? sqlTableStatement) {
  var parser = SqlParser(sqlTableStatement);
  if (parser.parseTokens(['create', 'table'])) {
    // optional
    parser.parseTokens(['if', 'not', 'exists']);
    return parser.getNextToken();
  }
  return null;
}

Future<List<String>> dbExportSql(Database db) async {
  var statements = <String>[];
  await db.transaction((Transaction txn) async {
    var tableRows = await txn.rawQuery('SELECT sql FROM sqlite_master');

    Future exportTable(String table) async {
      var contentRows = await txn.rawQuery('SELECT * from $table');
      for (var contentRow in contentRows) {
        var values = <String>[];
        for (var value in contentRow.values) {
          if (value == null) {
            values.add('NULL');
          } else if (value is num) {
            values.add(value.toString());
          } else if (value is List<int>) {
            values.add("x'${utils.hex(value)}'");
          } else {
            values.add("'${sanitizeText(value.toString())}'");
          }
        }
        statements.add('INSERT INTO $table VALUES (${values.join(',')});');
      }
    }

    // First handle all the regular tables
    for (var tableRow in tableRows) {
      var sql = tableRow.values.first as String?;
      var table = extractTableName(sql);
      if (table != null && !isSystemTable(unescapeText(table))) {
        statements.add(fixStatement(sql!));
        await exportTable(table);
      }
    }

    // Handle system table sqlite_sequence
    statements.add('DELETE FROM sqlite_sequence;');
    await exportTable('sqlite_sequence');

    // handle views and trigger
    for (var tableRow in tableRows) {
      var sql = tableRow.values.first as String?;
      var table = extractTableName(sql);
      if (table == null) {
        // We know this is not a table
        statements.add(fixStatement(sql!));
      }
    }
  });
  return statements;
}

Future dbImportSql(Database db, List<String> sqlStatements) async {
  var batch = db.batch();
  for (var statement in sqlStatements) {
    batch.execute(statement);
  }
  await batch.commit(noResult: true);
}
