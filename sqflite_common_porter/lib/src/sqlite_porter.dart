import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;
import 'package:sqflite_common/utils/utils.dart';
import 'package:sqflite_common_porter/src/sql_parser.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

/// Remove extra ; if any
String fixStatement(String sql) {
  sql = sql.trim();
  if (sql.endsWith(';')) {
    return sql.substring(0, sql.length - 1);
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

/// Export a database as list of string
Future<List<String>> dbExportSql(Database db) async {
  var statements = <String>[];
  await db.transaction((Transaction txn) async {
    var metaRows = await txn.rawQuery(
      'SELECT sql, type, name FROM sqlite_master',
    );
    // devPrint(metaRows);
    var tableRows = metaRows.where((row) => row['type'] == 'table');
    var otherRows = metaRows.where((row) => row['type'] != 'table');

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
        statements.add('INSERT INTO $table VALUES (${values.join(',')})');
      }
    }

    // First handle all the regular tables
    for (var tableRow in tableRows) {
      var sql = tableRow['sql'] as String?;
      var table = tableRow['name'] as String?;
      if (table != null && !isSystemTable(unescapeText(table)) && sql != null) {
        statements.add(fixStatement(sql));
        await exportTable(table);
      }
    }

    // Create other items (view, trigger)
    for (var row in otherRows) {
      var sql = row['sql'] as String?;
      if (sql != null) {
        statements.add(fixStatement(sql));
      }
    }

    var sqliteSequenceTableFound =
        tableRows.where((row) => row['name'] == 'sqlite_sequence').isNotEmpty;

    if (sqliteSequenceTableFound) {
      // Handle system table sqlite_sequence
      statements.add('DELETE FROM sqlite_sequence');
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
    }

    // The version!
    final rows = await txn.rawQuery('PRAGMA user_version');
    var version = firstIntValue(rows) ?? 0;
    if (version != 0) {
      statements.add('PRAGMA user_version = $version');
    }
  });
  return statements;
}

/// Import options
class SqlImportOptions {
  /// Max batch size during import, could be needed if the export is huge.
  final int importBatchSize;

  SqlImportOptions(this.importBatchSize);
}

/// Import a database from a list of statements.
///
/// db must be an empty database.
Future<void> dbImportSql(
  Database db,
  List<String> sqlStatements, {
  SqlImportOptions? options,
}) async {
  var importBatchSize = options?.importBatchSize;
  late Batch batch;
  var batchSize = 0;
  void createBatch() {
    batch = db.batch();
    batchSize = 0;
  }

  Future<void> commitBatch() async {
    if (batchSize > 0) {
      await batch.commit(noResult: true);
    }
  }

  // Create first batch
  createBatch();
  for (var statement in sqlStatements) {
    batch.execute(statement);
    batchSize++;
    if (importBatchSize != null) {
      if (batchSize >= importBatchSize) {
        await commitBatch();
        createBatch();
      }
    }
  }
  // commit last batch if needed
  await commitBatch();
}

/// Import a database and open it
///
Future<Database> openDatabaseFromSqlImport(
  DatabaseFactory factory,
  String path,
  List<String> sqlStatements, {
  SqlImportOptions? options,
  OpenDatabaseOptions? openDatabaseOptions,
}) async {
  await factory.deleteDatabase(path);
  var db = await factory.openDatabase(path, options: openDatabaseOptions);
  await dbImportSql(db, sqlStatements, options: options);
  return db;
}
