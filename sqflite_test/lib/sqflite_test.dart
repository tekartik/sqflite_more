library sqflite_test;

import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite_server/sqflite.dart';
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:sqflite_server/src/sqflite_client.dart';

class SqfliteServerTestContext extends SqfliteServerContext {
  String envUrl;
  int envPort;
  String url;

  Future<SqfliteClient> connectClientPort({int port}) async {
    if (client == null) {
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
        await connectClient(url);
      } catch (e) {
        print(e);
      }
      if (client == null) {
        var displayPort =
            port ?? parseSqfliteServerUrlPort(url, defaultValue: 0);
        print('''
sqflite server not running on $url
Check that the sqflite_server_app is running on the proper port on a connected
iOS device/simulator, Android device/emulator

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
    return client;
  }

  Future<String> initDeleteDb(String dbName) async {
    var databasesPath = await createDirectory(null);
    // print(databasePath);
    String path = join(databasesPath, dbName);
    await databaseFactory.deleteDatabase(path);
    return path;
  }

  static Future<SqfliteServerTestContext> connect() async {
    var context = SqfliteServerTestContext();
    var sqfliteClient = await context.connectClientPort();
    if (sqfliteClient == null) {
      var url = context.url;
      var port = parseSqfliteServerUrlPort(url);
      print('''
sqflite server not running on $url
Check that the sqflite_server_app is running on the proper port
Android: 
  check that you have forwarded tcp ip on Android
  \$ adb forward tcp:$port tcp:$port

''');
    } else {
      return context;
    }
    return null;
  }

  @override
  Future close() async {
    await client?.close();
  }

  @override
  Future<T> sendRequest<T>(String method, dynamic param) async {
    if (_debugModeOn) {
      print('$param');
    }
    T t = await super.sendRequest(method, param);
    if (_debugModeOn) {
      print(t);
    }
    return t;
  }

  @override
  Future<T> invoke<T>(String method, dynamic param) async {
    T t = await super.invoke(method, param);
    return t;
  }

  bool _debugModeOn = false;

  @deprecated
  Future devSetDebugModeOn(bool on) async {
    _debugModeOn = on ?? false;
  }
}
