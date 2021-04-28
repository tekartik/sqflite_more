import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  group('sqflite', () {
    SqfliteServerDatabaseFactory? databaseFactory;

    setUpAll(() async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      var sqfliteServer = await SqfliteServer.serve(
          webSocketChannelServerFactory: factory.server,
          factory: databaseFactoryFfi);
      databaseFactory = await SqfliteServerDatabaseFactory.connect(
          sqfliteServer.url,
          webSocketChannelClientFactory: factory.client);
    });

    tearDownAll(() async {
      await databaseFactory!.close();
    });

    test('getDatabasesPath', () async {
      var databasesPath = await databaseFactory!.getDatabasesPath();
      expect(databasesPath, isNotNull);
    });

    test('deleteDatabase', () async {
      await databaseFactory!.deleteDatabase('dummy');
    });
  });
}
