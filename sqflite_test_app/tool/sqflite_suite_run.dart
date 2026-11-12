// Runs the shared sqflite_common_test suite with the sqflite plugin on
// Android (the running emulator or one launched) or macOS:
//
//   dart run tool/sqflite_suite_run.dart [--target android|macos] [--help]
import 'dart:io';

import 'package:sqflite_support/sqflite_suite_run.dart';

Future<void> main(List<String> args) => sqfliteSuiteRunMain(
  args,
  SqfliteSuiteApp.ofToolScript(
    Platform.script,
    targets: [SqfliteSuiteTarget.android, SqfliteSuiteTarget.macos],
    deviceTest: 'integration_test/sqflite_plugin_all_test.dart',
  ),
);
