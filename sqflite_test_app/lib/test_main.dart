import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite_example/main.dart' as example;
import 'package:sqflite_example/manual_test_page.dart';
import 'package:sqflite_test_app/src/log_service_main.dart';
import 'package:sqflite_test_app/src/perf_main.dart';
import 'package:sqflite_test_app/src/porter_main.dart';
import 'package:tekartik_test_menu_flutter/test.dart';

import 'src/server_main.dart';

void main() {
  mainMenu(() {
    item('sqlite example app', () {
      example.main();
    });
    menu('more', () {
      serverMain();
      porterMain();
      logServiceMain();
      perfMain();
    });

    item('manual', () async {
      var manalApp = const ManualApp();
      runApp(manalApp);
      await manalApp.done;
      // restart
      //main();
    });
  }, showConsole: true);
}

class ManualApp extends StatelessWidget {
  const ManualApp({super.key});

  //final _doneCompleter = Completer();
  Future? get done => null;

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ManualTestPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final Completer? doneCompleter;

  const HomePage({super.key, this.doneCompleter});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    () async {
      await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (context) => const ManualApp()));
      try {
        widget.doneCompleter?.complete();
      } catch (e) {
        // should not happen
        print(e);
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
