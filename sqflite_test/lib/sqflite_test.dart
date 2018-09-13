library sqflite_test;

import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_server/sqflite_context.dart';
import 'package:sqflite_server/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tekartik_common_utils/int_utils.dart';

class SqliteServerTestContext implements SqfliteContext {
  final _initLock = Lock();
  SqfliteServerDatabaseFactory _databaseFactory;

  String envUrl;
  int envPort;
  Future init({int port}) async {
    if (_databaseFactory == null) {
      await _initLock.synchronized(() async {
        if (_databaseFactory == null) {
          String url;
          if (port != null) {
            url = getSqfliteServerUrl(port: port);
          } else {
            envUrl = String.fromEnvironment(sqfliteServerUrlEnvKey);
            envPort = parseInt(String.fromEnvironment(sqfliteServerPortEnvKey));

            url = envUrl;
            if (url == null) {
              url = getSqfliteServerUrl(port: envPort);
            }
          }

          try {
            _databaseFactory = await SqfliteServerDatabaseFactory.connect(url);
          } catch (e) {
            print(e);
          }
          if (databaseFactory == null) {
            var displayPort =
                port ?? parseSqfliteServerUrlPort(url, defaultValue: 0);
            print('''
sqflite server not running on $url
Check that the sqflite_server_app is running on the proper port
Android: 
  check that you have forwarded tcp ip on Android
  \$ adb forward tcp:$displayPort tcp:$displayPort

''');
            if (port == null) {
              print('''
url/port can be overriden using env variables
$sqfliteServerUrlEnvKey: ${envUrl ?? ''}
$sqfliteServerPortEnvKey: ${envPort ?? ''}

''');
            }
          }
        }
      });
    }
  }

  @override
  DatabaseFactory get databaseFactory => _databaseFactory;
}

SqliteServerTestContext _sqliteServerTestContext;
SqliteServerTestContext get sqliteServerTestContext =>
    _sqliteServerTestContext ??= SqliteServerTestContext();
