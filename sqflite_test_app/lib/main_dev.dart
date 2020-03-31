import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_test_app/main.dart';

import 'test_main.dart' as test;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sqfliteTestAppInit(sqfliteLogLevel: sqfliteLogLevelVerbose);
  test.main();
}
