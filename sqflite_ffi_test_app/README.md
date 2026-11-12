# sqflite_ffi_test_app

Runs the shared `sqflite_common_test` suite (`all_test.dart`) with
`sqflite_common_ffi` only, no plugin:

- on a device: `integration_test/sqflite_ffi_all_test.dart` (Android, iOS,
  Linux, macOS, Windows),
- in Chrome: `test_web/sqflite_ffi_web_all_test.dart` with
  `sqflite_common_ffi_web` (worker and `sqlite3.wasm` set up next to it).

```bash
# Android: the running emulator (or device), or the AVD launched then stopped
dart run tool/sqflite_suite_run.dart
dart run tool/sqflite_suite_run.dart --avd Pixel_9 --keep
# iOS: the booted simulator, or the latest iPhone booted (DeviceHub) then
# shut down; --no-window to boot it headless
dart run tool/sqflite_suite_run.dart -t ios
dart run tool/sqflite_suite_run.dart -t ios --simulator "iPhone 17" --keep
# Desktop, web (dart2js or dart2wasm)
dart run tool/sqflite_suite_run.dart -t linux
dart run tool/sqflite_suite_run.dart -t macos
dart run tool/sqflite_suite_run.dart -t web --compiler dart2wasm
# One group or test
dart run tool/sqflite_suite_run.dart -N exception
```

The tool prints the failures as they come and a summary (passed, skipped,
failed, duration), its exit code is non zero on a failure. The platform
folders are git-ignored, created by `flutter create` when missing.
