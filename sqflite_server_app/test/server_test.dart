// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.
//import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_server_app/src/prefs.dart';

void main() {
  group('prefs', () {
    SqfliteServerDatabaseFactory? databaseFactory;

    test('factory', () async {
      // run in test to display information in console
      // if the server is not running
      // logs from setUpAll are skipped in the ID
      var factory = await initSqfliteServerDatabaseFactory();
      await factory?.close();
    });
    setUpAll(() async {
      databaseFactory = await initSqfliteServerDatabaseFactory();
    });

    tearDownAll(() async {
      await databaseFactory?.close();
    });

    test('factory', () async {
      var factory = await initSqfliteServerDatabaseFactory();
      await factory?.close();
    });

    test('load and set', () async {
      // Always test if the factory is available before each test
      if (databaseFactory != null) {
        var prefs =
            Prefs(databaseFactory: databaseFactory, dbName: 'prefs_test.db');
        await prefs.delete();

        expect(prefs.port, sqfliteServerDefaultPort);
        expect(prefs.showConsole, isTrue);
        expect(prefs.autoStart, isFalse);
        await prefs.load();
        await prefs.setPort(1234);
        await prefs.setShowConsole(false);
        await prefs.setAutoStart(true);

        void check(Prefs prefs) {
          expect(prefs.port, 1234);
          expect(prefs.showConsole, isFalse);
          expect(prefs.autoStart, isTrue);
        }

        check(prefs);
        prefs.port = 5678;
        await prefs.load();
        check(prefs);

        prefs =
            Prefs(databaseFactory: databaseFactory, dbName: 'prefs_test.db');
        await prefs.load();
        check(prefs);
      }
    });
  });
}
