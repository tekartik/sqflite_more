import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_test_app/src/sqflite_import.dart';
import 'package:tekartik_app_platform/app_platform.dart';
import 'package:tekartik_test_menu_flutter/test.dart';

import 'test_main.dart' as test;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  platformInit();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  test.main();
}

// int _sqfliteLogLevelService = 0x1000;

int? _sqfliteLogLevel;

Future sqfliteTestAppInit({int? sqfliteLogLevel}) async {
  _sqfliteLogLevel = sqfliteLogLevel;
  WidgetsFlutterBinding.ensureInitialized();
  platformInit();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  databaseFactory = FactoryDelegate(factory: databaseFactory);
  if (sqfliteLogLevel != null && sqfliteLogLevel != sqfliteLogLevelNone) {
    try {
      // ignore: deprecated_member_use
      await databaseFactory.setLogLevel(sqfliteLogLevel);
    } catch (e) {
      if (kDebugMode) {
        print('error setLogLevel($e)');
      }
    }
  }
}

Future run({int? sqfliteLogLevel}) async {
  await sqfliteTestAppInit(sqfliteLogLevel: sqfliteLogLevel);
  test.main();
}

class FactoryDelegate with SqfliteDatabaseFactoryMixin {
  final SqfliteDatabaseFactory _factory;

  SqfliteDatabaseFactory get factory => _factory;

  FactoryDelegate({required DatabaseFactory factory})
      : _factory = factory as SqfliteDatabaseFactory;

  @override
  Future<T> invokeMethod<T>(String method, [arguments]) async {
    var map = <String, Object?>{
      'method': method,
      if (arguments != null) 'arguments': arguments
    };
    // For now assume sqfliteLogLevelService (bit field)
    var shouldLogLevelService = _sqfliteLogLevel == sqfliteLogLevelVerbose;
    if (shouldLogLevelService) {
      write('IN: $map');
    }
    var result = await _factory.invokeMethod<T>(method, arguments);
    if (shouldLogLevelService) {
      write('OUT: $result');
    }
    return result;
  }
}
