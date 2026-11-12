// Manual test, run explicitly (`dart test` alone never runs it):
//
//   dart test test/sqflite_repo/run_ios_ffi_runner_test_manual.dart
//
// The sqflite repo sqflite_ffi_test_app, its console test runner (flutter run -t
// lib/main_sqflite_ffi_test_runner.dart, quits once the tests are done).
//
// iOS: the booted simulator, else the one of SQFLITE_TEST_SIMULATOR (a
// name or a UDID) or the first iPhone of the latest runtime, booted (shown
// in DeviceHub) then shut down.
//
// The sqflite repo is the one next to sqflite_more (SQFLITE_REPO_DIR).
import 'package:sqflite_support/sqflite_repo_test.dart';

void main() {
  sqfliteRepoTargetTests(
    apps: ['ffi'],
    targets: [FlutterDeviceTarget.ios],
    kinds: [SqfliteRepoTestKind.testRunner],
  );
}
