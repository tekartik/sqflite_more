import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_exp1_common/sqflite_exp1_common.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

/// Exp1 with sqflite_ffi: Android, iOS, macOS, Linux and Windows.
///
/// SQLite bundled by package:sqlite3 on every platform, run in a sqflite
/// isolate shared by all the Flutter isolates. The default databases path
/// (`.dart_tool/sqflite_common_ffi/databases` in the current directory) is
/// not writable on mobile: databases go in the application support
/// directory.
Future<void> main() async {
  exp1EnsureInitialized();
  var factory = sqfliteDatabaseFactoryFfi;
  var supportDir = await getApplicationSupportDirectory();
  await factory.setDatabasesPath(join(supportDir.path, 'databases'));
  await runExp1App(
    Exp1Setup(
      variant: 'sqflite_ffi',
      implementation: 'sqflite_ffi (sqlite3 bundled)',
      databaseFactory: factory,
    ),
  );
}
