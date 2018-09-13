import 'package:test/test.dart';

import 'package:sqflite_test/sqflite_test.dart';

void main() {
  var context = SqliteServerTestContext();
  group('test_context', () {
    test('factory', () async {
      await context.init();
    });
    test('factory_dummy', () async {
      await context.init(port: 8500);
    });
    test('factory_invalid', () async {
      await context.init(port: 85000);
    });
  });
}
