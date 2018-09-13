export 'src/factory.dart' show SqfliteServerDatabaseFactory;
import 'dart:async';

import 'package:sqflite/src/database_factory.dart';
import 'package:sqflite_server/sqflite.dart';
import 'package:sqflite_server/sqflite_context.dart';
import 'package:sqflite_server/sqflite_server.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

// overrides  SQFLITE_SERVER_PORT
const sqfliteServerUrlEnvKey = 'SQFLITE_SERVER_URL';
const sqfliteServerPortEnvKey = 'SQFLITE_SERVER_PORT';

String getSqfliteServerUrl({int port}) {
  port ??= sqfliteServerDefaultPort;
  return 'ws://localhost:$port';
}

int parseSqfliteServerUrlPort(String url, {int defaultValue}) {
  int port = parseInt(url.split('\:').last);
  return port ?? defaultValue;
}

final sqfliteServerDefaultUrl = getSqfliteServerUrl();

Future<SqfliteServerDatabaseFactory> initSqfliteServerDatabaseFactory() async {
  SqfliteServerDatabaseFactory databaseFactory;
  var envUrl = String.fromEnvironment(sqfliteServerUrlEnvKey);
  var envPort = parseInt(String.fromEnvironment(sqfliteServerPortEnvKey));

  var url = envUrl;
  if (url == null) {
    url = getSqfliteServerUrl(port: envPort);
  }
  try {
    databaseFactory = await SqfliteServerDatabaseFactory.connect(url);
  } catch (e) {
    print(e);
  }
  if (databaseFactory == null) {
    print('''
sqflite server not running on $url
Check that the sqflite_server_app is running on the proper port
Android: 
  check that you have forwarded tcp ip on Android
  \$ adb forward tcp:8501 tcp:8501

url/port can be overriden using env variables
$sqfliteServerUrlEnvKey: ${envUrl ?? ''}
$sqfliteServerPortEnvKey: ${envPort ?? ''}

''');
  }
  return databaseFactory;
}

SqfliteServerContext _sqfliteServerContext;
SqfliteServerContext get sqfliteServerContext =>
    _sqfliteServerContext ??= SqfliteServerContext();

class SqfliteServerContext implements SqfliteContext {
  final _initLock = Lock();
  SqfliteServerDatabaseFactory _databaseFactory;

  Future init({int port}) async {
    port ??= sqfliteServerDefaultPort;
    if (_databaseFactory == null) {
      await _initLock.synchronized(() async {
        if (_databaseFactory == null) {
          var url = getSqfliteServerUrl(port: port);

          try {
            _databaseFactory = await SqfliteServerDatabaseFactory.connect(url);
          } catch (e) {
            print(e);
          }
          if (databaseFactory == null) {
            print('''
sqflite server not running on $url
Check that the sqflite_server_app is running on the proper port
Android: 
  check that you have forwarded tcp ip on Android
  \$ adb forward tcp:$port tcp:$port

''');
          }
        }
      });
    }
  }

  @override
  DatabaseFactory get databaseFactory => _databaseFactory;
}
