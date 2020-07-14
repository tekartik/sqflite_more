import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqflite_ffi_test/src/windows/setup.dart';

void main() {
  test('sqlite3 simple test', () {
    print(Directory.current);
    if (Platform.isWindows) {
      windowsInit();
    }
    final database = sqlite3.openInMemory();
    var version = database.userVersion;
    expect(version, 0);
    database.dispose();
  });
}
