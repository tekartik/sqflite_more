import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite_dev.dart';
import 'package:sqflite_common/sqflite_dev.dart';
import 'package:sqflite_porter/src/utils.dart'; // ignore: implementation_imports
import 'package:sqflite_test_app/main.dart';
import 'package:tekartik_test_menu/test.dart';
import 'package:tekartik_test_menu_flutter/test.dart';
import 'sqflite_import.dart';

void logServiceMain() {
  group('log_service', () {
    item('Turn on', () async {
      if (!(databaseFactory is FactoryDelegate)) {
        // ignore: deprecated_member_use
        await (databaseFactory as SqfliteDatabaseFactory)
            .setLogLevel(sqfliteLogLevelVerbose);
        setMockDatabaseFactory(FactoryDelegate(factory: databaseFactory));
      }
    });
    item('Turn off', () async {
      if (databaseFactory is FactoryDelegate) {
        // ignore: deprecated_member_use
        setMockDatabaseFactory((databaseFactory as FactoryDelegate).factory);
      }
    });
    test('open/close in memory single instance false', () async {
      await databaseFactory.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
    });
  });
}
