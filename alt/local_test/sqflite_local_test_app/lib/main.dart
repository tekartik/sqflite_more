import 'package:flutter/material.dart';
import 'package:sqflite_test_app/main.dart' as test_main;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await test_main.main();
}
