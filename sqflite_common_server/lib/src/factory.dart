import 'package:path/path.dart' as path;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/src/sqflite_import.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

import 'import.dart';

/// A sqflite [DatabaseFactory] whose calls run on a `SqfliteServer`.
///
/// Relative paths resolve in the server databases path.
class SqfliteServerDatabaseFactory extends SqfliteDatabaseFactoryBase {
  /// Factory of a connected [context], see [connect].
  SqfliteServerDatabaseFactory(this.context);

  /// The connection to the server.
  final SqfliteServerContext context;

  /// Connects to the server at [url] (`ws://host:port`).
  ///
  /// [webSocketChannelClientFactory] defaults to the io one (real web socket).
  /// Throws if no server answers or if the server is older than the client
  /// protocol. [close] when done.
  static Future<SqfliteServerDatabaseFactory> connect(
    String url, {
    WebSocketChannelClientFactory? webSocketChannelClientFactory,
  }) async {
    var sqfliteContext = await SqfliteServerContext.connect(
      url,
      webSocketChannelClientFactory: webSocketChannelClientFactory,
    );

    return SqfliteServerDatabaseFactory(sqfliteContext);
  }

  path.Context get pathContext => context.pathContext;

  /// Closes the connection; the server closes the databases left open.
  Future close() async {
    await context.close();
  }

  @override
  Future<T> invokeMethod<T>(String method, [Object? arguments]) =>
      context.invoke<T>(method, arguments);

  // deleteDatabase is not overridden: the base one closes and forgets a
  // single instance database before sending the deleteDatabase method.

  /// Same as the base one, with the server path context (posix).
  @override
  Future<String> fixPath(String path) async {
    if (SqfliteDatabaseFactoryMixin.isInMemoryDatabasePath(path)) {
      // `file::memory:` is converted to `:memory:` as in the base.
      return inMemoryDatabasePath;
    } else if (path.startsWith('file:')) {
      // uri, untouched
    } else {
      if (context.pathContext.isRelative(path)) {
        path = pathContext.join(await getDatabasesPath(), path);
      }
      path = pathContext.absolute(pathContext.normalize(path));
    }
    return path;
  }
}
