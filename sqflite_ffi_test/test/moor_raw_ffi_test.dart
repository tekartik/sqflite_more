import 'package:flutter_test/flutter_test.dart';
import 'package:moor_ffi/database.dart';

void main() {
  test('moor_ffi simple test', () {
    final database = Database.memory();
    var version = database.userVersion();
    expect(version, 0);
    database.close();
  });
}
