import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_server/sqflite.dart';
import 'package:sqflite_server/sqflite_server.dart';
import 'package:tekartik_web_socket/web_socket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sqflite', () {
    const channel = MethodChannel('com.tekartik.sqflite');

    final log = <MethodCall>[];
    String response;

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
      return response;
    });

    SqfliteServerDatabaseFactory databaseFactory;

    setUpAll(() async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      var sqfliteServer = await SqfliteServer.serve(
          webSocketChannelServerFactory: factory.server);
      databaseFactory = await SqfliteServerDatabaseFactory.connect(
          sqfliteServer.url,
          webSocketChannelClientFactory: factory.client);
    });

    tearDownAll(() async {
      await databaseFactory.close();
    });

    tearDown(() {
      log.clear();
    });

    test('getDatabasesPath', () async {
      response = 'path';
      var databasesPath = await databaseFactory.getDatabasesPath();
      expect(databasesPath, 'path');
    });

    test('deleteDatabase', () async {
      await databaseFactory.deleteDatabase('dummy');
    });
  });
}
