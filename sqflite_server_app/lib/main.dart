import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_server_app/page/main_page.dart';
import 'package:tekartik_app_platform/app_platform.dart';

void main() => run();

DatabaseFactory? databaseFactory;

void run() {
  WidgetsFlutterBinding.ensureInitialized();
  platformInit();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    databaseFactory = sqflite.databaseFactory;
  }

  runApp(const SqfliteServerApp());
}

class SqfliteServerApp extends StatelessWidget {
  const SqfliteServerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: const SqfliteServerHomePage(title: 'SQFlite server'),
    );
  }
}

MaterialPageRoute<Object?> get homePageRoute =>
    MaterialPageRoute<Object?>(builder: (BuildContext context) {
      return const SqfliteServerHomePage(title: 'SQFlite server page');
    });
