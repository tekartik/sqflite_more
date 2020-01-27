import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moor_ffi/database.dart';
import 'package:sqflite_ffi_test/src/windows/setup.dart';

void main() {
  test('moor_ffi simple test', () {
    print(Directory.current);
    if (Platform.isWindows) {
      windowsInit();
    }
    final database = Database.memory();
    var version = database.userVersion();
    expect(version, 0);
    database.close();
  });
}
