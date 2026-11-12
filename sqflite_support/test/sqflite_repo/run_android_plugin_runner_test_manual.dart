// Manual test, run explicitly (`dart test` alone never runs it):
//
//   dart test test/sqflite_repo/run_android_plugin_runner_test_manual.dart
//
// The sqflite repo sqflite_plugin_test_app, its console test runner (flutter run -t
// lib/main_sqflite_plugin_test_runner.dart, quits once the tests are done).
//
// Android: the running emulator (or device), else the AVD of
// SQFLITE_TEST_AVD (the only AVD when there is one) launched then stopped.
//
// The sqflite repo is the one next to sqflite_more (SQFLITE_REPO_DIR).
import 'package:sqflite_support/sqflite_repo_test.dart';

void main() {
  sqfliteRepoTargetTests(
    apps: ['plugin'],
    targets: [FlutterDeviceTarget.android],
    kinds: [SqfliteRepoTestKind.testRunner],
  );
}
