// The client resolves paths with posix rules (servers on Android, iOS, macOS,
// Linux): a Windows server is not supported yet.
@TestOn('!windows')
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:test/test.dart';

/// The shared sqflite_common_test suite run through a server serving ffi, over
/// a memory web socket (client and server in this isolate).
Future<void> main() async {
  sqfliteFfiInit();
  var channelFactory = webSocketChannelFactoryMemory;
  var server = await SqfliteServer.serve(
    webSocketChannelServerFactory: channelFactory.server,
    factory: databaseFactoryFfi,
  );
  var databaseFactory = await SqfliteServerDatabaseFactory.connect(
    server.url,
    webSocketChannelClientFactory: channelFactory.client,
  );
  tearDownAll(() async {
    await databaseFactory.close();
    await server.close();
  });
  group('server', () {
    all.run(SqfliteLocalTestContext(databaseFactory: databaseFactory));
  });
}
