export 'src/setup_flutter.dart' show sqfliteInitAsMockMethodCallHandler;

import 'package:sqflite_ffi_test/sqflite_ffi.dart';
import 'package:sqflite_ffi_test/src/setup_flutter.dart';

/// Initialize using ffi.
///
/// It is however preferable to use the `DatabaseFactory` object
void sqfliteInit() {
  sqfliteFfiInit();
  sqfliteInitAsMockMethodCallHandler();
}
