import 'package:sqflite/sqflite.dart';
import 'package:sqflite_exp1_common/sqflite_exp1_common.dart';

/// Exp1 with the sqflite plugin: Android, iOS and macOS.
///
/// SQLite of the platform (Android framework, iOS/macOS system library),
/// databases in the plugin default folder: `<data>/databases` on Android,
/// Documents on iOS and macOS.
Future<void> main() async {
  exp1EnsureInitialized();
  await runExp1App(
    Exp1Setup(
      variant: 'sqflite',
      implementation: 'sqflite plugin',
      databaseFactory: databaseFactorySqflitePlugin,
    ),
  );
}
