import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_exp1_common/sqflite_exp1_common.dart';
import 'package:sqflite_ffi/sqflite_ffi.dart';

/// Exp1 merging all the variants: the sqflite plugin when supported
/// (Android, iOS, macOS), sqflite_ffi on Linux and Windows,
/// sqflite_common_ffi_web on the web.
///
/// Both sqflite and sqflite_ffi register a default `databaseFactory`; the
/// app never uses it, it passes the chosen factory explicitly.
Future<void> main() async {
  exp1EnsureInitialized();
  await runExp1App(await exp1MergedSetup());
}

/// The setup of the current platform.
Future<Exp1Setup> exp1MergedSetup() async {
  if (kIsWeb) {
    return Exp1Setup(
      variant: 'merged',
      implementation: 'sqflite_common_ffi_web (wasm, shared worker)',
      databaseFactory: databaseFactoryFfiWeb,
    );
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return Exp1Setup(
        variant: 'merged',
        implementation: 'sqflite plugin',
        databaseFactory: databaseFactorySqflitePlugin,
      );
    case TargetPlatform.linux:
    case TargetPlatform.windows:
    case TargetPlatform.fuchsia:
      var factory = sqfliteDatabaseFactoryFfi;
      var supportDir = await getApplicationSupportDirectory();
      await factory.setDatabasesPath(join(supportDir.path, 'databases'));
      return Exp1Setup(
        variant: 'merged',
        implementation: 'sqflite_ffi (sqlite3 bundled)',
        databaseFactory: factory,
      );
  }
}
