import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_exp1_common/sqflite_exp1_common.dart';

/// Exp1 with sqflite_common_ffi_web: web only.
///
/// SQLite (wasm) runs in a shared worker persisting to IndexedDB, all tabs
/// share the database. Needs `web/sqlite3.wasm` and `web/sqflite_sw.js`
/// (`dart run sqflite_common_ffi_web:setup`).
Future<void> main() async {
  exp1EnsureInitialized();
  await runExp1App(
    Exp1Setup(
      variant: 'web',
      implementation: 'sqflite_common_ffi_web (wasm, shared worker)',
      databaseFactory: databaseFactoryFfiWeb,
    ),
  );
}
