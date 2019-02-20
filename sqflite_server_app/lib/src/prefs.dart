import 'package:path/path.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_server/sqflite_server.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

class Prefs {
  Prefs({DatabaseFactory databaseFactory, String dbName})
      : _databaseFactory = databaseFactory ?? sqflite.databaseFactory,
        dbName = dbName ?? defaultDbName;

  static const defaultDbName = 'sqlflite_server_app_prefs.db';
  final DatabaseFactory _databaseFactory;
  final String dbName;
  final _openLock = Lock();

  // server port
  int port = sqfliteServerDefaultPort;
  bool showConsole = true;
  bool autoStart = false;

  Database _db;

  Future<Database> get db async {
    if (_db == null) {
      return await _openLock.synchronized(() async {
        if (_db == null) {
          var databasePath = await _databaseFactory.getDatabasesPath();
          var dbPath = join(databasePath, dbName);
          _db = await _databaseFactory.openDatabase(dbPath,
              options: OpenDatabaseOptions(
                  version: 1,
                  onCreate: (Database db, int version) async {
                    await db.execute(
                        'CREATE TABLE Pref (name TEXT PRIMARY KEY, textValue TEXT, intValue INTEGER)');
                  }));
        }
        return _db;
      });
    }
    return _db;
  }

  Future<List<Map<String, dynamic>>> load() async {
    var db = await this.db;
    var list =
        await db.query('Pref', columns: ['name', 'textValue', 'intValue']);
    //devPrint(list);
    for (Map<String, dynamic> item in list) {
      var prefName = item['name'] as String;
      switch (prefName) {
        case 'port':
          port = item['intValue'] as int;
          break;
        case 'showConsole':
          showConsole = item['intValue'] == 1;
          break;
        case 'autoStart':
          autoStart = item['intValue'] == 1;
          break;
      }
    }
    return list;
  }

  @override
  String toString() {
    return <String, dynamic>{
      'port': port,
      'showConsole': showConsole,
      'autoStart': autoStart
    }.toString();
  }

  // testing only
  // close and delete
  Future delete() async {
    if (_db != null) {
      await _db.close();
      _db = null;
    }
    var databasePath = await _databaseFactory.getDatabasesPath();
    var dbPath = join(databasePath, dbName);
    await _databaseFactory.deleteDatabase(dbPath);
  }

  Future setPort(int port) async {
    this.port = port;
    await _setIntValue('port', port);
  }

  Future setShowConsole(bool showConsole) async {
    this.showConsole = showConsole != false;
    int intValue = this.showConsole ? 1 : 0;
    await _setIntValue('showConsole', intValue);
  }

  Future setAutoStart(bool autoStart) async {
    this.autoStart = autoStart == true;
    int intValue = this.autoStart ? 1 : 0;
    await _setIntValue('autoStart', intValue);
  }

  Future _setIntValue(String name, int intValue) async {
    await _db.execute(
        'INSERT OR REPLACE INTO Pref(name, intValue) VALUES (?, ?)',
        <dynamic>[name, intValue]);
  }
}
