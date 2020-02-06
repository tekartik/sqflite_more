import 'package:flutter/services.dart';
import 'package:sqflite_ffi_test/src/database_factory_ffi.dart';
import 'package:sqflite_ffi_test/src/method_call.dart';
import 'package:sqflite_ffi_test/src/sqflite_ffi_exception.dart';

/// Use `sqflite_ffi` as the mock implementation for unit test or regular
/// application using `sqflite`
///
/// Currently supporting Linux.
void sqfliteInitAsMockMethodCallHandler() {
  const channel = MethodChannel('com.tekartik.sqflite');

  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    try {
      return await FfiMethodCall(methodCall.method, methodCall.arguments)
          .handleInIsolate();
    } on SqfliteFfiException catch (e) {
      // Re-convert to a Platform exception to make flutter services happy
      throw PlatformException(
          code: e.code, message: e.message, details: e.details);
    }
  });
}
