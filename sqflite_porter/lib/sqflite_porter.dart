/// Deprecated, use `package:sqflite_common_porter/sqflite_porter.dart`.
///
/// Re-exports [dbExportSql] (a database as SQL statements: schema, rows and
/// user version) and [dbImportSql] (replays them in an empty database) of
/// sqflite_common_porter, for the apps that still import this library.
library;

export 'package:sqflite_common_porter/sqflite_porter.dart'
    show dbExportSql, dbImportSql;
