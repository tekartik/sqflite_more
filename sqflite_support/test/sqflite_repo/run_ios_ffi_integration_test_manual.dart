// Manual test, run explicitly (`dart test` alone never runs it):
//
//   dart test test/sqflite_repo/run_ios_ffi_integration_test_manual.dart
//
// The sqflite repo sqflite_ffi_test_app, its integration test (flutter test integration_test).
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
    kinds: [SqfliteRepoTestKind.integrationTest],
  );
}
