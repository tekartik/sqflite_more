import 'package:sqflite/src/database_factory.dart' show SqfliteDatabaseFactory;
import 'package:sqflite_server/src/constant.dart';
import 'package:sqflite_server/src/sqflite_client.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';

class SqfliteServerDatabaseFactory extends SqfliteDatabaseFactory {
  final SqfliteClient _sqfliteClient;
  SqfliteServerDatabaseFactory._(this._sqfliteClient);

  static Future<SqfliteServerDatabaseFactory> connect(String url,
      {WebSocketChannelClientFactory webSocketChannelClientFactory}) async {
    var sqfliteClient = await SqfliteClient.connect(url,
        webSocketChannelClientFactory: webSocketChannelClientFactory);
    if (sqfliteClient != null) {
      return SqfliteServerDatabaseFactory._(sqfliteClient);
    }
    return null;
  }

  Future close() async {
    await _sqfliteClient.close();
  }

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      _sqfliteClient.invoke<T>(method, arguments);

  @override
  Future deleteDatabase(String path) async {
    return await _sqfliteClient
        .sendRequest(methodDeleteDatabase, <String, dynamic>{keyPath: path});
  }
}
