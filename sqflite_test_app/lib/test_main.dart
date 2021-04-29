import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite_example/manual_test_page.dart';
import 'package:sqflite_test_app/src/log_service_main.dart';
import 'package:sqflite_test_app/src/porter_main.dart';
import 'package:tekartik_test_menu_flutter/test.dart';
import 'package:sqflite_example/main.dart' as example;
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
    });

    item('manual', () async {
      var manalApp = ManualApp();
      runApp(manalApp);
      await manalApp.done;
      // restart
      //main();
    });
  }, showConsole: true);
}

class ManualApp extends StatelessWidget {
  //final _doneCompleter = Completer();
  Future? get done => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ManualTestPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final Completer? doneCompleter;

  const HomePage({Key? key, this.doneCompleter}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    () async {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => ManualApp()));
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
    return Scaffold();
  }
}
