import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:sqflite_test/sqflite_test.dart';

Future main() async {
  group('test_context', () {
    test('factory', () async {
      var context = SqfliteServerTestContext();
      await context.connectClientPort();
      await context.close();
    });
    test('factory_dummy', () async {
      var context = SqfliteServerTestContext();
      await context.connectClientPort(port: 8500);
      await context.close();
    });
    test('factory_invalid', () async {
      var context = SqfliteServerTestContext();
      await context.connectClientPort(port: 85000);
      await context.close();
    });
  });
}
