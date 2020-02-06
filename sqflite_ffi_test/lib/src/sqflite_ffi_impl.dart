import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:moor_ffi/database.dart' as ffi;
import 'package:path/path.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite_ffi_test/src/constant.dart';
import 'package:sqflite_ffi_test/src/method_call.dart';
import 'package:synchronized/extension.dart';
import 'package:synchronized/synchronized.dart';

import 'import.dart';

final _debug = false; // devWarning(true); // false
// final _useIsolate = true; // devWarning(true); // true the default!

String _prefix = '[sqflite]';

/// By id
var ffiDbs = <int, SqfliteFfiDatabase>{};

/// By path
var ffiSingleInstanceDbs = <String, SqfliteFfiDatabase>{};

var _lastFfiId = 0;

//SqfliteIsolate _isolate;

class SqfliteFfiException implements DatabaseException {
  final String code;
  final String message;
  Map<String, dynamic> details;

  SqfliteFfiException(
      {@required this.code, @required this.message, this.details});

  @override
  bool isDatabaseClosedError() {
    // TODO: implement isDatabaseClosedError
    return null;
  }

  @override
  bool isNoSuchTableError([String table]) {
    // TODO: implement isNoSuchTableError
    return null;
  }

  @override
  bool isOpenFailedError() {
    // TODO: implement isOpenFailedError
    return null;
  }

  @override
  bool isReadOnlyError() {
    // TODO: implement isReadOnlyError
    return null;
  }

  @override
  bool isSyntaxError() {
    // TODO: implement isSyntaxError
    return null;
  }

  @override
  bool isUniqueConstraintError([String field]) {
    // TODO: implement isUniqueConstraintError
    return null;
  }

  @override
  String toString() {
    var map = <String, dynamic>{};
    if (details != null) {
      map['details'] = details;
    }
    return 'SqfliteFfiException($code, $message} ${super.toString()} $map';
  }
}

int logLevel = sqfliteLogLevelNone;

class SqfliteFfiOperation {
  String method;
  String sql;
  List sqlArguments;
}

class SqfliteFfiDatabase {
  final int id;
  final bool singleInstance;
  final String path;
  final bool readOnly;
  final ffi.Database _ffiDb;
  final int logLevel;

  String get _prefix => '[sqflite-$id]';

  SqfliteFfiDatabase(this.id, this._ffiDb,
      {@required this.singleInstance,
      @required this.path,
      @required this.readOnly,
      @required this.logLevel}) {
    ffiDbs[id] = this;
  }

  Map<String, dynamic> toDebugMap() {
    var map = <String, dynamic>{
      'path': path,
      'id': id,
      'readOnly': readOnly,
      'singleInstance': singleInstance
    };
    return map;
  }

  int getLastInsertId() {
    var id = _ffiDb.getLastInsertId();
    if (logLevel >= sqfliteLogLevelSql) {
      print('$_prefix Inserted $id');
    }
    return id;
  }

  @override
  String toString() => toDebugMap().toString();

  void close() {
    logResult(result: 'Closing database $this');
    _ffiDb.close();
  }

  Future handleExecute({String sql, List sqlArguments}) async {
    logSql(sql: sql, sqlArguments: sqlArguments);
    //database.ffiDb.execute(sql);
    if (sqlArguments?.isNotEmpty ?? false) {
      var preparedStatement = _ffiDb.prepare(sql);
      try {
        preparedStatement.execute(sqlArguments);
        return null;
      } finally {
        preparedStatement.close();
      }
    } else {
      _ffiDb.execute(sql);
    }
  }

  void logResult({String result}) {
    if (result != null && (logLevel >= sqfliteLogLevelSql)) {
      print('$_prefix $result');
    }
  }

  void logSql({String sql, List sqlArguments, String result}) {
    if (logLevel >= sqfliteLogLevelSql) {
      print(
          '$_prefix $sql${(sqlArguments?.isNotEmpty ?? false) ? ' $sqlArguments' : ''}');
      logResult(result: result);
    }
  }

  Future handleQuery({String sql, List sqlArguments}) async {
    var preparedStatement = _ffiDb.prepare(sql);

    try {
      logSql(sql: sql, sqlArguments: sqlArguments);
      var result = preparedStatement.select(sqlArguments);
      logResult(result: 'Found ${result.length} rows');
      return packResult(result);
    } finally {
      preparedStatement.close();
    }
  }

  int getUpdatedRows() {
    var rowCount = _ffiDb.getUpdatedRows();
    if (logLevel >= sqfliteLogLevelSql) {
      print('$_prefix Modified $rowCount rows');
    }
    return rowCount;
  }
}

class SqfliteFfiHandler {
  final multiInstanceLocks = <String, Lock>{};
  final mainLock = Lock();
}

final sqfliteFfiHandler = SqfliteFfiHandler();

class _MultiInstanceLocker {
  final String path;

  _MultiInstanceLocker(this.path);

  @override
  int get hashCode => path?.hashCode ?? 0;

  @override
  bool operator ==(other) {
    if (other is _MultiInstanceLocker) {
      return other.path == path;
    }
    return false;
  }
}

/// Extension on MethodCall
extension SqfliteFfiMethodCallHandler on FfiMethodCall {
  Future<T> synchronized<T>(Future<T> Function() action) async {
    var path = getPath() ?? getDatabase()?.path;
    if (isInMemory(path)) {
      return await action();
    }
    return await (_MultiInstanceLocker(path).synchronized(action));
  }

  Future handleImpl() async {
    // devPrint('$this');
    try {
      if (_debug) {
        print('handle $this');
      }
      dynamic result = await rawHandle();

      if (_debug) {
        print('result: $result');
      }

      // devPrint('result: $result');
      return result;
    } catch (e, st) {
      if (_debug) {
        print('error: $e');
      }

      if (e is ffi.SqliteException) {
        var database = getDatabase();
        var sql = getSql();
        var sqlArguments = getSqlArguments();
        var wrapped = wrapSqlException(e, details: <String, dynamic>{
          'database': database.toDebugMap(),
          'sql': sql,
          'arguments': sqlArguments
        });
        // devPrint(wrapped);
        throw wrapped;
      }
      var database = getDatabase();
      var sql = getSql();
      var sqlArguments = getSqlArguments();
      if (_debug) {
        print('$e in ${database?.toDebugMap()}');
      }
      String code;
      String message;
      Map<String, dynamic> details;
      if (e is SqfliteFfiException) {
        // devPrint('throwing $e');
        code = e.code;
        message = e.message;
        details = e.details;
      } else {
        code = anyErrorCode;
        message = e.toString();
      }
      if (_debug) {
        print('handleError: $e');
        print('stackTrace : $st');
      }
      throw SqfliteFfiException(
          code: code,
          message: message,
          details: <String, dynamic>{
            if (database != null) 'database': database.toDebugMap(),
            if (sql != null) 'sql': sql,
            if (sqlArguments != null) 'arguments': sqlArguments,
            if (details != null) 'details': details,
          });
    }
  }

  /// Handle a method call
  Future<dynamic> rawHandle() async {
    switch (method) {
      case 'openDatabase':
        return await handleOpenDatabase();
      case 'closeDatabase':
        return await handleCloseDatabase();

      case 'query':
        return await handleQuery();
      case 'execute':
        return await handleExecute();
      case 'insert':
        return await handleInsert();
      case 'update':
        return await handleUpdate();
      case 'batch':
        return await handleBatch();

      case 'getDatabasesPath':
        return await handleGetDatabasesPath();
      case 'deleteDatabase':
        return await handleDeleteDatabase();
      case 'options':
        return await handleOptions();
      case 'debugMode':
        return await handleDebugMode();
      default:
        throw ArgumentError('Invalid method $method $this');
    }
  }

  String getDatabasesPath() {
    return absolute(join('.dart_tool', 'sqflite_ffi_test', 'databases'));
  }

  Future handleOpenDatabase() async {
    //dePrint(arguments);
    var path = arguments['path'];

    //devPrint('opening $path');
    var singleInstance = (arguments['singleInstance'] as bool) ?? false;
    var readOnly = (arguments['readOnly'] as bool) ?? false;
    if (singleInstance) {
      var database = ffiSingleInstanceDbs[path];
      if (database != null) {
        if (logLevel >= sqfliteLogLevelVerbose) {
          database.logResult(
              result: 'Reopening existing single database $database');
        }
        return database;
      }
    }
    ffi.Database ffiDb;
    try {
      if (path == inMemoryDatabasePath) {
        ffiDb = ffi.Database.memory();
      } else {
        if (readOnly) {
          if (!(await File(path).exists())) {
            throw StateError('file $path not found');
          }
        } else {
          if (!(await File(path).exists())) {
            // Make sure its parent exists
            try {
              await Directory(dirname(path)).create(recursive: true);
            } catch (_) {}
          }
        }
        ffiDb = ffi.Database.open(path);
      }
    } on ffi.SqliteException catch (e) {
      throw wrapSqlException(e, code: 'open_failed');
    }

    var id = ++_lastFfiId;
    var database = SqfliteFfiDatabase(id, ffiDb,
        singleInstance: singleInstance,
        path: path,
        readOnly: readOnly,
        logLevel: logLevel);
    database.logResult(result: 'Opening database $database');
    if (singleInstance) {
      ffiSingleInstanceDbs[path] = database;
    }
    //devPrint('opened: $database');

    return <String, dynamic>{'id': id};
  }

  Future handleCloseDatabase() async {
    var database = getDatabaseOrThrow();
    if (database.singleInstance ?? false) {
      ffiSingleInstanceDbs.remove(database.path);
    }
    database.close();
  }

  SqfliteFfiDatabase getDatabaseOrThrow() {
    var database = getDatabase();
    if (database == null) {
      throw StateError('Database ${getDatabaseId()} not found');
    }
    return database;
  }

  SqfliteFfiDatabase getDatabase() {
    var id = getDatabaseId();
    var database = ffiDbs[id];
    return database;
  }

  int getDatabaseId() {
    if (arguments is Map) {
      return arguments['id'] as int;
    }
    return null;
  }

  String getSql() {
    var sql = arguments['sql'] as String;
    return sql;
  }

  bool isInMemory(String path) {
    return path == inMemoryDatabasePath;
  }

  // Return the path argument if any
  String getPath() {
    var arguments = this.arguments;
    if (arguments is Map) {
      var path = arguments['path'] as String;
      if ((path != null) && !isInMemory(path) && isRelative(path)) {
        path = join(getDatabasesPath(), path);
      }
      return path;
    }
    return null;
  }

  /// Check the arguments
  List getSqlArguments() {
    var arguments = this.arguments;
    if (arguments != null) {
      var sqlArguments = arguments['arguments'] as List;
      if (sqlArguments != null) {
        // Check the argument, make it stricter
        for (var argument in sqlArguments) {
          if (argument == null) {
          } else if (argument is num) {
          } else if (argument is String) {
          } else if (argument is Uint8List) {
          } else {
            throw ArgumentError(
                'Invalid sql argument type \'${argument.runtimeType}\': $argument');
          }
        }
      }
      return sqlArguments;
    }
    return null;
  }

  bool getNoResult() {
    var noResult = arguments['noResult'] as bool;
    return noResult;
  }

  List<SqfliteFfiOperation> getOperations() {
    var operations = <SqfliteFfiOperation>[];
    arguments['operations'].cast<Map>().forEach((operationArgument) {
      operations.add(SqfliteFfiOperation()
        ..sql = operationArgument['sql'] as String
        ..sqlArguments = operationArgument['arguments'] as List
        ..method = operationArgument['method'] as String);
    });
    return operations;
  }

  Future handleQuery() async {
    var database = getDatabaseOrThrow();
    var sql = getSql();
    var sqlArguments = getSqlArguments();
    return database.handleQuery(sqlArguments: sqlArguments, sql: sql);
  }

  SqfliteFfiException wrapSqlException(ffi.SqliteException e,
      {String code, Map<String, dynamic> details}) {
    return SqfliteFfiException(
        // Hardcoded
        code: sqliteErrorCode,
        message: code == null ? '$e' : '$code: $e',
        details: details);
  }

  Future handleExecute() async {
    var database = getDatabaseOrThrow();
    var sql = getSql();
    var sqlArguments = getSqlArguments();

    var writeAttempt = false;
    // Handle some cases
    // PRAGMA user_version =
    if ((sql?.toLowerCase()?.trim()?.startsWith('pragma user_version =')) ??
        false) {
      writeAttempt = true;
    }
    if (writeAttempt && (database.readOnly ?? false)) {
      throw SqfliteFfiException(
          code: sqliteErrorCode, message: 'Database readonly');
    }

    return database.handleExecute(sql: sql, sqlArguments: sqlArguments);
  }

  Future handleOptions() async {
    if (arguments is Map) {
      logLevel = arguments['logLevel'] ?? sqfliteLogLevelNone;
    }
    return null;
  }

  Future handleDebugMode() async {
    if (arguments == true) {
      logLevel = sqfliteLogLevelVerbose;
    }
    return null;
  }

  Future handleInsert() async {
    var database = getDatabaseOrThrow();
    if (database.readOnly ?? false) {
      throw SqfliteFfiException(
          code: sqliteErrorCode, message: 'Database readonly');
    }

    await handleExecute();

    var id = database.getLastInsertId();
    if (logLevel >= sqfliteLogLevelSql) {
      print('$_prefix Inserted id $id');
    }
    return id;
  }

  Future handleUpdate() async {
    var database = getDatabaseOrThrow();
    if (database.readOnly ?? false) {
      throw SqfliteFfiException(
          code: sqliteErrorCode, message: 'Database readonly');
    }

    await handleExecute();

    var rowCount = database.getUpdatedRows();

    return rowCount;
  }

  Future handleBatch() async {
    //devPrint(arguments);
    var database = getDatabaseOrThrow();
    var operations = getOperations();
    List<Map<String, dynamic>> results;
    var noResult = getNoResult() ?? false;
    if (!noResult) {
      results = <Map<String, dynamic>>[];
    }
    for (var operation in operations) {
      switch (operation.method) {
        case 'insert':
          {
            await database.handleExecute(
                sql: operation.sql, sqlArguments: operation.sqlArguments);
            if (!noResult) {
              results
                  .add(<String, dynamic>{'result': database.getLastInsertId()});
            }
            break;
          }
        case 'execute':
          {
            await database.handleExecute(
                sql: operation.sql, sqlArguments: operation.sqlArguments);
            if (!noResult) {
              results.add(<String, dynamic>{'result': null});
            }
            break;
          }
        case 'query':
          {
            var result = await database.handleQuery(
                sql: operation.sql, sqlArguments: operation.sqlArguments);
            if (!noResult) {
              results.add(<String, dynamic>{'result': result});
            }
            break;
          }
        case 'update':
          {
            await database.handleExecute(
                sql: operation.sql, sqlArguments: operation.sqlArguments);
            if (!noResult) {
              results
                  .add(<String, dynamic>{'result': database.getUpdatedRows()});
            }
            break;
          }
        default:
          throw 'batch operation ${operation.method} not supported';
      }
    }
    return results;
  }

  Future handleGetDatabasesPath() async {
    return getDatabasesPath();
  }

  Future handleDeleteDatabase() async {
    var path = getPath();
    //TODO handle single instance database
    //devPrint('deleting $path');

    var singleInstanceDatabase = ffiSingleInstanceDbs[path];
    if (singleInstanceDatabase != null) {
      singleInstanceDatabase.close();
      ffiSingleInstanceDbs.remove(path);
    }

    // Ignore failure
    try {
      await File(path).delete();
    } catch (_) {}
  }
}

// final sqfliteFfiMethodCallHandler = SqfliteFfiMethodCallHandler();
Map<String, dynamic> packResult(ffi.Result result) {
  var columns = result.columnNames;
  var rows = result.rows;
  // This is what sqflite expected
  return <String, dynamic>{'columns': columns, 'rows': rows};
}
