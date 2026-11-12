// Manual test, run explicitly (`dart test` alone never runs it):
//
//   dart test test/sqflite_repo/run_all_plugin_test_manual.dart
//
// The sqflite repo sqflite_plugin_test_app: its integration test then its
// console test runner, on Android then iOS.
//
// Android: the running emulator (or device), else the AVD of
// SQFLITE_TEST_AVD (the only AVD when there is one) launched then stopped.
// iOS: the booted simulator, else the one of SQFLITE_TEST_SIMULATOR (a
// name or a UDID) or the first iPhone of the latest runtime, booted (shown
// in DeviceHub) then shut down.
// One device per target for all the runs.
//
// The sqflite repo is the one next to sqflite_more (SQFLITE_REPO_DIR).
import 'package:sqflite_support/sqflite_repo_test.dart';

void main() {
  sqfliteRepoTargetTests(
    apps: ['plugin'],
    targets: [FlutterDeviceTarget.android, FlutterDeviceTarget.ios],
    kinds: [
      SqfliteRepoTestKind.integrationTest,
      SqfliteRepoTestKind.testRunner,
    ],
  );
}
