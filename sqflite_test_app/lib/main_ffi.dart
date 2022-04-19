import 'dart:io';

import 'package:sqflite_test_app/src/sqflite_import.dart';
import 'package:tekartik_app_platform/app_platform.dart';

import 'test_main.dart' as test;

Future main() async {
  platformInit();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  test.main();
}
