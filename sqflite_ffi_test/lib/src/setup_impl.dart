import 'dart:io';

import 'package:sqflite_ffi_test/src/windows/setup.dart';

/// Init sqflite_ffi dll loaded
void sqfliteFfiSetup() {
  if (Platform.isWindows) {
    windowsInit();
  }
}
