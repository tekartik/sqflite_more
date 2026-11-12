/// Runs the shared sqflite_common_test suite of a test app on Android (an
/// emulator found or launched), iOS (a simulator found or booted), a desktop
/// or Chrome, and summarizes its json
/// reporter output.
library;

export 'src/ios_simulator_utils.dart';
export 'src/sqflite_suite_run.dart';
export 'src/test_json_reporter.dart';
