/// Runs the shared sqflite_common_test suite of a test app on Android (an
/// emulator found or launched), iOS (a simulator found or booted), a desktop
/// or Chrome, and summarizes its json
/// reporter output.
library;

export 'package:tekartik_flutter_build/device_test.dart'
    show TestJsonSummary, TestJsonFailure, FlutterTargetDeviceException;

export 'src/sqflite_suite_run.dart';
