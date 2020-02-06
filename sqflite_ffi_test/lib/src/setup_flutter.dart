import 'package:flutter/services.dart';
import 'package:sqflite_ffi_test/src/database_factory_ffi.dart';
import 'package:sqflite_ffi_test/src/method_call.dart';

/// Use `sqflite_ffi` as the mock implementation for unit test or regular
/// application using `sqflite`
///
/// Currently supporting Linux.
void sqfliteInitAsMockMethodCallHandler() {
  const channel = MethodChannel('com.tekartik.sqflite');

  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    return FfiMethodCall(methodCall.method, methodCall.arguments)
        .handleInIsolate();
  });
}
