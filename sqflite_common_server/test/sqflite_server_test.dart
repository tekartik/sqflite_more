import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/src/import.dart';
import 'package:sqflite_common_server/src/sqflite_client.dart';
import 'package:sqflite_common_server/src/sqflite_server.dart';
import 'package:test/test.dart';

void main() {
  group('server', () {
    test('fixParam', () {
      var param = fixParam('insert', {
        'arguments': [
          [1, 2, 3]
        ],
      });
      expect(param['arguments']![0], const TypeMatcher<Uint8List>());
      var param2 = fixParam('batch', {
        'operations': [
          {
            'method': 'insert',
            'sql': 'INSERT INTO test (blob) VALUES (?)',
            'arguments': [
              [1, 2, 3]
            ]
          }
        ],
        'id': 1
      });
      expect(
          (((param2['operations'] as List)[0] as Map)['arguments'] as List)[0],
          const TypeMatcher<Uint8List>());
    });
    test('init', () async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      var sqfliteServer = await SqfliteServer.serve(
          webSocketChannelServerFactory: factory.server,
          factory: databaseFactoryFfi);
      var sqfliteClient = await SqfliteClient.connect(
        sqfliteServer.url,
        webSocketChannelClientFactory: factory.client,
      );

      var result = await sqfliteClient
          .invoke<Map>('openDatabase', {'path': inMemoryDatabasePath});
      expect(result['id'], const TypeMatcher<int>());

      expect(sqfliteClient, isNotNull);

      await sqfliteServer.close();
    });
  });
}
