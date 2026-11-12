// The shared sqflite_common_test suite in a browser with
// sqflite_common_ffi_web. Run it with tool/sqflite_suite_run.dart --target web
// (it sets up the worker and sqlite3.wasm next to this file first).
@TestOn('browser')
library;

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:test/test.dart';

void main() {
  var factory = createDatabaseFactoryFfiWeb(
    options: SqfliteFfiWebOptions(sharedWorkerUri: Uri.parse('sqflite_sw.js')),
  );
  all.run(SqfliteLocalTestContext(databaseFactory: factory));
}
