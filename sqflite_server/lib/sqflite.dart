export 'src/factory.dart' show SqfliteServerDatabaseFactory;
import 'dart:async';

import 'package:sqflite/src/database_factory.dart';
import 'package:sqflite_server/sqflite.dart';
import 'package:sqflite_server/sqflite_context.dart';
import 'package:sqflite_server/sqflite_server.dart';
import 'package:sqflite_server/src/constant.dart';
import 'package:sqflite_server/src/sqflite_client.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';

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
  SqfliteServerDatabaseFactory _databaseFactory;

  SqfliteClient _client;
  SqfliteClient get client => _client;

  @override
  bool get supportsWithoutRowId =>
      client.serverInfo?.supportsWithoutRowId == true;

  Future<T> sendRequest<T>(String method, dynamic param) async {
    return await _client.sendRequest<T>(method, param);
  }

  Future<T> invoke<T>(String method, dynamic param) async {
    //var map = <String, dynamic>{keyMethod: method, keyParam: param};
    var result = await _client.invoke<T>(method, param);
    return result;
  }

  /*
  Future init({int port}) async {
    port ??= sqfliteServerDefaultPort;
    if (_client == null) {
      await _initLock.synchronized(() async {
        if (_client == null) {
          var url = getSqfliteServerUrl(port: port);

          try {
              _client =
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
  */

  Future<SqfliteClient> connectClient(String url,
      {WebSocketChannelClientFactory webSocketChannelClientFactory}) async {
    SqfliteClient sqfliteClient;
    try {
      sqfliteClient = await SqfliteClient.connect(url,
          webSocketChannelClientFactory: webSocketChannelClientFactory);
      if (sqfliteClient != null) {
        this._client = sqfliteClient;
        _databaseFactory = SqfliteServerDatabaseFactory(this);
      }
      return sqfliteClient;
    } catch (e) {
      print(e);
    }
    return null;
  }

  @override
  DatabaseFactory get databaseFactory => _databaseFactory;

  @override
  Future<String> createDirectory(String path) async {
    return await _client.sendRequest<String>(
        methodCreateDirectory, <String, dynamic>{keyPath: path});
  }

  @override
  Future<String> deleteDirectory(String path) async {
    return await _client.sendRequest<String>(
        methodDeleteDirectory, <String, dynamic>{keyPath: path});
  }

  static Future<SqfliteServerContext> connect(String url,
      {WebSocketChannelClientFactory webSocketChannelClientFactory}) async {
    var context = SqfliteServerContext();
    var sqfliteClient = await (context.connectClient(url,
        webSocketChannelClientFactory: webSocketChannelClientFactory));
    if (sqfliteClient == null) {
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

  Future close() async {
    await _client?.close();
    _client = null;
  }
}
