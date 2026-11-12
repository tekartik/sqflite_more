/// Runs the tests of the sqflite repo test apps (packages_flutter
/// sqflite_ffi_test_app and sqflite_plugin_test_app) on a device of a target
/// found or launched for the run: their integration test (`flutter test`)
/// and their console test runner (`flutter run`).
///
/// Used by the manual tests `test/run_*_test_manual.dart`.
library;

export 'package:tekartik_flutter_build/device_test.dart'
    show FlutterDeviceTarget, FlutterTargetDeviceOptions;

export 'src/sqflite_repo_test.dart';
