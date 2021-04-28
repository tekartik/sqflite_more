import 'package:path/path.dart' as path;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/src/constant.dart';
import 'package:sqflite_common_server/src/sqflite_import.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_web_socket/web_socket.dart';

class SqfliteServerDatabaseFactory extends SqfliteDatabaseFactoryBase {
  SqfliteServerDatabaseFactory(this.context);

  final SqfliteServerContext context;

  static Future<SqfliteServerDatabaseFactory> connect(String url,
      {WebSocketChannelClientFactory? webSocketChannelClientFactory}) async {
    var sqfliteContext = await SqfliteServerContext.connect(url,
        webSocketChannelClientFactory: webSocketChannelClientFactory);

    return SqfliteServerDatabaseFactory(sqfliteContext);
  }

  path.Context get pathContext => context.pathContext;

  Future close() async {
    await context.close();
  }

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      context.invoke<T>(method, arguments);

  @override
  Future deleteDatabase(String path) async {
    return await context.sendRequest<String>(
        methodSqfliteDeleteDatabase, <String, dynamic>{keyPath: path});
  }

  // overrident to use the proper path context
  @override
  Future<String> fixPath(String path) async {
    if (path == inMemoryDatabasePath) {
      // nothing
    } else {
      if (context.pathContext.isRelative(path)) {
        path = pathContext.join(await getDatabasesPath(), path);
      }
      path = pathContext.absolute(pathContext.normalize(path));
    }
    return path;
  }
}
