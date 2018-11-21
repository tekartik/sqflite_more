import 'package:sqflite_server/src/sqflite_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sqflite_server/sqflite_server.dart';
import 'package:tekartik_web_socket/web_socket.dart';

void main() {
  group('server', () {
    test('init', () async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      var sqfliteServer = await SqfliteServer.serve(
          webSocketChannelServerFactory: factory.server);
      var sqfliteClient = await SqfliteClient.connect(
        sqfliteServer.url,
        webSocketChannelClientFactory: factory.client,
      );
      expect(sqfliteClient, isNotNull);

      await sqfliteServer.close();
    });
  });
}
