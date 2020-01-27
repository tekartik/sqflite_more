import 'package:flutter/services.dart';

import 'src/sqflite_ffi_impl.dart';

/// Use `sqflite_ffi` as the mock implementation for unit test.
///
/// Currently supporting Linux.
void setAsMockMethodCallHandler() {
  const channel = MethodChannel('com.tekartik.sqflite');

  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    return methodCall.handle();
  });
}
