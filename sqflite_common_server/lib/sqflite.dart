import 'package:path/path.dart' as path;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_server/sqflite_context.dart';
import 'package:sqflite_common_server/src/constant.dart';
import 'package:sqflite_common_server/src/factory.dart';
import 'package:sqflite_common_server/src/sqflite_client.dart';
import 'package:sqflite_common_server/src/utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';

export 'package:sqflite_common_server/src/common_public.dart';
export 'package:sqflite_common_server/src/factory.dart'
    show SqfliteServerDatabaseFactory;

// overrides  SQFLITE_SERVER_PORT
const sqfliteServerUrlEnvKey = 'SQFLITE_SERVER_URL';
const sqfliteServerPortEnvKey = 'SQFLITE_SERVER_PORT';

int? parseSqfliteServerUrlPort(String url, {int? defaultValue}) {
  var port = parseInt(url.split(':').last);
  return port ?? defaultValue;
}

final sqfliteServerDefaultUrl = getSqfliteServerUrl();

Future<SqfliteServerDatabaseFactory?> initSqfliteServerDatabaseFactory() async {
  SqfliteServerDatabaseFactory? databaseFactory;
  var envPort = parseInt(String.fromEnvironment(sqfliteServerPortEnvKey,
      defaultValue: sqfliteServerDefaultPort.toString()));
  var envUrl = String.fromEnvironment(sqfliteServerUrlEnvKey,
      defaultValue: getSqfliteServerUrl(port: envPort));

  try {
    databaseFactory = await SqfliteServerDatabaseFactory.connect(envUrl);
  } catch (e) {
    print(e);
  }
  if (databaseFactory == null) {
    print('''
sqflite server not running on $envUrl
Check that the sqflite_server_app is running on the proper port
Android: 
  check that you have forwarded tcp ip on Android
  \$ adb forward tcp:$envPort tcp:$envPort

url/port can be overriden using env variables
$sqfliteServerUrlEnvKey: $envUrl
$sqfliteServerPortEnvKey: $envPort

''');
  }
  return databaseFactory;
}

SqfliteServerContext? _sqfliteServerContext;

SqfliteServerContext get sqfliteServerContext =>
    _sqfliteServerContext ??= SqfliteServerContext();

class SqfliteServerContext implements SqfliteContext {
  SqfliteServerDatabaseFactory? _databaseFactory;

  SqfliteClient? _client;

  SqfliteClient? get client => _client;

  @override
  bool get supportsWithoutRowId =>
      client!.serverInfo.supportsWithoutRowId == true;

  Future<T?> sendRequest<T>(String method, Object? param) async {
    return await _client!.sendRequest<T>(method, param);
  }

  Future<T> invoke<T>(String method, Object? param) async {
    //var map = <String, Object?>{keyMethod: method, keyParam: param};
    var result = await _client!.invoke<T>(method, param);
    return result;
  }

  Future<SqfliteClient> connectClient(String url,
      {WebSocketChannelClientFactory? webSocketChannelClientFactory}) async {
    SqfliteClient sqfliteClient;
    sqfliteClient = await SqfliteClient.connect(url,
        webSocketChannelClientFactory: webSocketChannelClientFactory);

    _client = sqfliteClient;
    _databaseFactory = SqfliteServerDatabaseFactory(this);
    return sqfliteClient;
  }

  @override
  DatabaseFactory get databaseFactory => _databaseFactory!;

  @override
  Future<String> createDirectory(String? path) async {
    return await _client!.sendRequest<String>(
        methodCreateDirectory, <String, Object?>{keyPath: path});
  }

  @override
  Future<String> deleteDirectory(String? path) async {
    return await _client!.sendRequest<String>(
        methodDeleteDirectory, <String, Object?>{keyPath: path});
  }

  static Future<SqfliteServerContext> connect(String url,
      {WebSocketChannelClientFactory? webSocketChannelClientFactory}) async {
    var context = SqfliteServerContext();
    await (context.connectClient(url,
        webSocketChannelClientFactory: webSocketChannelClientFactory));
    return context;
  }

  Future close() async {
    await _client?.close();
    _client = null;
  }

  @override
  bool get isAndroid => client!.serverInfo.isAndroid ?? false;

  @override
  bool get isIOS => client!.serverInfo.isIOS ?? false;

  @override
  bool get isMacOS => client!.serverInfo.isMacOS ?? false;

  @override
  bool get isLinux => client!.serverInfo.isLinux ?? false;

  @override
  bool get isWindows => client!.serverInfo.isWindows ?? false;

  // Force posix
  @override
  path.Context get pathContext => path.posix;

  @override
  Future<List<int>> readFile(String path) async {
    return (await _client!.sendRequest<List>(
            methodReadFile, <String, Object?>{keyPath: path}))
        .cast<int>();
  }

  @override
  Future<String> writeFile(String? path, List<int>? data) async {
    return await _client!.sendRequest<String>(
        methodWriteFile, <String, Object?>{keyPath: path, keyContent: data});
  }
}
