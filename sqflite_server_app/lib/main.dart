import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_server_app/page/main_page.dart';
import 'package:tekartik_app_platform/app_platform.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

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

  runApp(SqfliteServerApp());
}

class SqfliteServerApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: SqfliteServerHomePage(title: 'SQFlite server'),
    );
  }
}

MaterialPageRoute<Object?> get homePageRoute =>
    MaterialPageRoute<Object?>(builder: (BuildContext context) {
      return SqfliteServerHomePage(title: 'SQFlite server page');
    });
