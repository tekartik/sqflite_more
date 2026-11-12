# sqflite_test_app

Sqflite testing app

## Getting Started

```bash
flutter create .
flutter run
```

## Desktop build

```bash
flutter run -d windows
flutter run -d linux
```

Ensure you manage to build and run the google sample first in <https://github.com/google/flutter-desktop-embedding>

Desktop build use ffi [as described here](https://github.com/tekartik/sqflite_more/tree/master/sqflite_ffi_test)



## Shared suite

`integration_test/sqflite_plugin_all_test.dart` runs the shared
`sqflite_common_test` suite with the plugin on a device:

```bash
# Android: the running emulator (or device), or the AVD launched then stopped
dart run tool/sqflite_suite_run.dart [--avd <name>] [--keep] [-N <name>]
dart run tool/sqflite_suite_run.dart -t macos
```
