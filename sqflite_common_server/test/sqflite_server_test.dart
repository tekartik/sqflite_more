import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/src/import.dart';
import 'package:sqflite_common_server/src/sqflite_client.dart';
import 'package:sqflite_common_server/src/sqflite_server.dart';
import 'package:test/test.dart';

void main() {
  group('server', () {
    test('fixParam', () {
      var param = fixParam('insert', {
        'arguments': [
          [1, 2, 3],
        ],
      });
      expect(param['arguments']![0], const TypeMatcher<Uint8List>());
      var param2 = fixParam('batch', {
        'operations': [
          {
            'method': 'insert',
            'sql': 'INSERT INTO test (blob) VALUES (?)',
            'arguments': [
              [1, 2, 3],
            ],
          },
        ],
        'id': 1,
      });
      expect(
        (((param2['operations'] as List)[0] as Map)['arguments'] as List)[0],
        const TypeMatcher<Uint8List>(),
      );
    });
    test('fixParam writeDatabaseBytes', () {
      var param = fixParam('writeDatabaseBytes', {
        'path': 'test.db',
        'bytes': [1, 2, 3],
      });
      expect(param['bytes'], const TypeMatcher<Uint8List>());
      expect(param['bytes'], [1, 2, 3]);
    });
    test('init', () async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      var sqfliteServer = await SqfliteServer.serve(
        webSocketChannelServerFactory: factory.server,
        factory: databaseFactoryFfi,
      );
      var sqfliteClient = await SqfliteClient.connect(
        sqfliteServer.url,
        webSocketChannelClientFactory: factory.client,
      );

      var result = await sqfliteClient.invoke<Map>('openDatabase', {
        'path': inMemoryDatabasePath,
      });
      expect(result['id'], const TypeMatcher<int>());

      expect(sqfliteClient, isNotNull);

      await sqfliteServer.close();
    });

    test('blob in query and batch query results', () async {
      WebSocketChannelFactory factory = webSocketChannelFactoryMemory;
      var sqfliteServer = await SqfliteServer.serve(
        webSocketChannelServerFactory: factory.server,
        factory: databaseFactoryFfi,
      );
      var databaseFactory = await SqfliteServerDatabaseFactory.connect(
        sqfliteServer.url,
        webSocketChannelClientFactory: factory.client,
      );
      try {
        var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
        try {
          await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, b BLOB)',
          );
          await db.insert('Test', {
            'id': 1,
            'b': Uint8List.fromList([1, 2, 3]),
          });
          var value = (await db.query('Test')).first['b'];
          expect(value, isA<Uint8List>());
          expect(value, [1, 2, 3]);

          // Batch results are {'result': ...} lines.
          var batch = db.batch()..query('Test');
          var rows = (await batch.commit()).first as List;
          value = (rows.first as Map)['b'];
          expect(value, isA<Uint8List>());
          expect(value, [1, 2, 3]);
        } finally {
          await db.close();
        }
      } finally {
        await databaseFactory.close();
        await sqfliteServer.close();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
