/// Serve a sqflite `DatabaseFactory` over a web socket (JSON-RPC 2).
///
/// ```dart
/// var server = await SqfliteServer.serve(
///   factory: databaseFactoryFfi, // or the sqflite plugin databaseFactory
///   port: sqfliteServerDefaultPort, // 8501, a free port when omitted
/// );
/// print(server.url); // ws://localhost:8501
/// ```
///
/// Clients connect with `SqfliteServerDatabaseFactory.connect(server.url)`
/// (`package:sqflite_common_server/sqflite.dart`).
library;

export 'package:sqflite_common_server/src/common_public.dart';
export 'package:sqflite_common_server/src/sqflite_server.dart'
    show SqfliteServer, SqfliteServerNotifyCallback;
