export 'src/setup_flutter.dart' show sqfliteInitAsMockMethodCallHandler;

import 'package:sqflite/src/compat.dart';
import 'package:sqflite/src/constant.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_ffi_test/sqflite_ffi.dart';
import 'package:sqflite_ffi_test/src/mixin/factory.dart';
import 'package:sqflite_ffi_test/src/setup_flutter.dart';

/// Dev extension
extension SqfliteFfiDev on DatabaseFactory {
  /// Turns on debug mode if you want to see the SQL query
  /// executed natively.
  ///
  /// Deprecated for temp usage only
  @deprecated
  Future<void> setDebugModeOn([bool on = true]) async {
    await setOptions(SqfliteOptions(logLevel: sqfliteLogLevelVerbose));
  }

  /// Testing only.
  ///
  /// deprecated on purpose to remove from code.
  @deprecated
  Future<void> setOptions(SqfliteOptions options) async {
    await (this as SqfliteFfiInvokeHandler)
        .invokeMethod<dynamic>(methodOptions, options.toMap());
  }
}

/// Initialize using ffi.
///
/// It is however preferable to use the `DatabaseFactory` object
void sqfliteInit() {
  sqfliteFfiInit();
  sqfliteInitAsMockMethodCallHandler();
}
