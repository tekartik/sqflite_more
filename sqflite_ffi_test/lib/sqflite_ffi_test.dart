import 'package:sqflite_ffi_test/sqflite.dart';
import 'package:sqflite_ffi_test/sqflite_ffi.dart';
//import 'src/sqflite_ffi_impl.dart';

/// Init sqflite_ffi_test
void sqfliteFfiTestInit() {
  sqfliteFfiInit();
  sqfliteInitAsMockMethodCallHandler();
}
