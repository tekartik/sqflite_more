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