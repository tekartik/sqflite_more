import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite_ffi_test/src/windows/setup.dart';

import 'src/sqflite_ffi_impl.dart';

/// Use `sqflite_ffi` as the mock implementation for unit test.
///
/// Currently supporting Linux.
void _setAsMockMethodCallHandler() {
  const channel = MethodChannel('com.tekartik.sqflite');

  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    return methodCall.handle();
  });
}

/// Init sqflite_ffi_test
void sqfliteFfiTestInit() {
  if (Platform.isWindows) {
    windowsInit();
  }
  _setAsMockMethodCallHandler();
}
