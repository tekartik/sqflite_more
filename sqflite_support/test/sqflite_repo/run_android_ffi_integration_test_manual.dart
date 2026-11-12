// Manual test, run explicitly (`dart test` alone never runs it):
//
//   dart test test/sqflite_repo/run_android_ffi_integration_test_manual.dart
//
// The sqflite repo sqflite_ffi_test_app, its integration test (flutter test integration_test).
//
// Android: the running emulator (or device), else the AVD of
// SQFLITE_TEST_AVD (the only AVD when there is one) launched then stopped.
//
// The sqflite repo is the one next to sqflite_more (SQFLITE_REPO_DIR).
import 'package:sqflite_support/sqflite_repo_test.dart';

void main() {
  sqfliteRepoTargetTests(
    apps: ['ffi'],
    targets: [FlutterDeviceTarget.android],
    kinds: [SqfliteRepoTestKind.integrationTest],
  );
}
