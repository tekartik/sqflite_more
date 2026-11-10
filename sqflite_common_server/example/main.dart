// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

/// A server serving the ffi implementation and a client using it, in the same
/// process over a memory web socket.
///
/// In real use the server runs in an app on a device (the sqflite plugin) and
/// the client in tests on the host, over a real web socket.
Future<void> main() async {
  sqfliteFfiInit();
  var channelFactory = webSocketChannelFactoryMemory;

  // Server side: any sqflite implementation factory.
  var server = await SqfliteServer.serve(
    factory: databaseFactoryFfi,
    webSocketChannelServerFactory: channelFactory.server,
  );

  // Client side: a regular sqflite DatabaseFactory.
  var factory = await SqfliteServerDatabaseFactory.connect(
    server.url,
    webSocketChannelClientFactory: channelFactory.client,
  );
  try {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Todo (id INTEGER PRIMARY KEY, title TEXT)',
          );
        },
      ),
    );
    await db.insert('Todo', {'title': 'Buy milk'});
    print(await db.query('Todo')); // [{id: 1, title: Buy milk}]
    await db.close();
  } finally {
    await factory.close();
    await server.close();
  }
}
