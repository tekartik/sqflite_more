// Runs the shared sqflite_common_test suite with sqflite_common_ffi on
// Android (the running emulator or one launched), iOS (the booted simulator
// or one booted), a desktop or Chrome:
//
//   dart run tool/sqflite_suite_run.dart [--target android|ios|linux|macos|web] [--help]
import 'dart:io';

import 'package:sqflite_support/sqflite_suite_run.dart';

Future<void> main(List<String> args) => sqfliteSuiteRunMain(
  args,
  SqfliteSuiteApp.ofToolScript(
    Platform.script,
    targets: [
      SqfliteSuiteTarget.android,
      SqfliteSuiteTarget.ios,
      SqfliteSuiteTarget.linux,
      SqfliteSuiteTarget.macos,
      SqfliteSuiteTarget.windows,
      SqfliteSuiteTarget.web,
    ],
    deviceTest: 'integration_test/sqflite_ffi_all_test.dart',
    webTest: 'test_web/sqflite_ffi_web_all_test.dart',
  ),
);
