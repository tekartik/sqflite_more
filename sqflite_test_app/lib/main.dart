import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_ffi_test/sqflite.dart';
import 'package:tekartik_app_platform/app_platform.dart';

import 'test_main.dart' as test;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  platformInit();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteInit();
  }
  test.main();
}
