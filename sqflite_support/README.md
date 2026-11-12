# Test and tools for sqflite

## Manual tests to run

`tool/manual_test/create_and_build.dart`

Create an empty project, add sqflite and build apk, ios and macos when available

Validates proper pod import for iOS and MacOS

## sqflite repo integration tests

`tool/sqflite_integration_test_run.dart` runs the integration tests of the
sqflite repo test apps (`packages_flutter/sqflite_ffi_test_app` and
`sqflite_plugin_test_app`, `flutter test integration_test -d <device>` as
their own `tool/run_integration_test*.dart`) on each target, one device for
all the apps of a target:

- android: the running emulator (or device), or an AVD launched then stopped,
- ios (macOS host): the booted simulator, or the latest iPhone booted
  (shown in DeviceHub on Xcode 27+) then shut down,
- the host desktop (macos, linux or windows).

The sqflite repo is expected next to sqflite_more (`--sqflite <dir>`), the
missing platform folders of the apps are created (`flutter create`).

```bash
# All the apps on all the targets (android, ios, macos on a Mac)
dart run tool/sqflite_integration_test_run.dart
# The plugin app on iOS and the host, headless simulator kept running
dart run tool/sqflite_integration_test_run.dart -a plugin -t ios -t host --no-window --keep
dart run tool/sqflite_integration_test_run.dart -t ios --simulator "iPhone 17" -N transaction
```

It prints a summary per app and target, its exit code is non zero on a
failure.

## sqflite repo manual tests

`test/sqflite_repo/run_*_test_manual.dart` run the sqflite repo test apps on
a device found or launched for the run (run explicitly, `dart test` alone
never runs them), each its integration test (`flutter test
integration_test`) or its console test runner (`flutter run -t
lib/main_sqflite_<app>_test_runner.dart`, quitting once the tests are done):

```bash
dart test test/sqflite_repo/run_ios_plugin_integration_test_manual.dart
dart test test/sqflite_repo/run_android_ffi_runner_test_manual.dart
# One app, or both, everything on Android then iOS (one device per target)
dart test test/sqflite_repo/run_all_plugin_test_manual.dart
dart test test/sqflite_repo/run_all_test_manual.dart
```

- Android: the running emulator, else the AVD of `SQFLITE_TEST_AVD` (needed
  with several AVDs) launched then stopped.
- iOS: the booted simulator, else the one of `SQFLITE_TEST_SIMULATOR` (a
  name or a UDID) or the first iPhone of the latest runtime, booted (shown
  in DeviceHub) then shut down.
- The variables can be set in the user environment (`ds env var set
  SQFLITE_TEST_AVD Pixel_9`); `SQFLITE_REPO_DIR` when the sqflite repo is not
  next to sqflite_more.

The console runner cannot see the end of the tests on Android (the test
reporter of the app writes to stdout, which logcat does not show): it quits
after 3 minutes without output and fails (exit code 2). Use the integration
test on Android.
