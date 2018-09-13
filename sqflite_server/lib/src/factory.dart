import 'package:sqflite/src/database_factory.dart' show SqfliteDatabaseFactory;
import 'package:sqflite_server/sqflite.dart';
import 'package:sqflite_server/src/constant.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';

class SqfliteServerDatabaseFactory extends SqfliteDatabaseFactory {
  final SqfliteServerContext context;
  // SqfliteClient get _sqfliteClient
  SqfliteServerDatabaseFactory(this.context);

  static Future<SqfliteServerDatabaseFactory> connect(String url,
      {WebSocketChannelClientFactory webSocketChannelClientFactory}) async {
    var sqfliteContext = await SqfliteServerContext.connect(url,
        webSocketChannelClientFactory: webSocketChannelClientFactory);
    if (sqfliteContext != null) {
      return SqfliteServerDatabaseFactory(sqfliteContext);
    }
    return null;
  }

  Future close() async {
    await context.close();
  }

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      context.invoke<T>(method, arguments);

  @override
  Future deleteDatabase(String path) async {
    return await context.sendRequest<String>(
        methodDeleteDatabase, <String, dynamic>{keyPath: path});
  }
}
