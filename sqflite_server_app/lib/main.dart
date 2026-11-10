import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_server_app/page/main_page.dart';
import 'package:tekartik_app_platform/app_platform.dart';

void main() => run();

/// The factory served, also holding the prefs: sqflite_common_ffi on Windows
/// and Linux, the sqflite plugin elsewhere.
///
/// Set on first use (a lazy top-level variable), so that the test menu
/// (lib/test_main.dart, which does not call [run]) has it too.
DatabaseFactory? databaseFactory = _initDatabaseFactory();

DatabaseFactory _initDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    // No default factory there (the sqflite plugin has no Windows and Linux
    // implementation): the sqflite_porter helpers of the test menu use it.
    sqflite.databaseFactory = databaseFactoryFfi;
    return databaseFactoryFfi;
  }
  return sqflite.databaseFactory;
}

void run() {
  WidgetsFlutterBinding.ensureInitialized();
  platformInit();
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

MaterialPageRoute<Object?> get homePageRoute => MaterialPageRoute<Object?>(
  builder: (BuildContext context) {
    return const SqfliteServerHomePage(title: 'SQFlite server page');
  },
);
