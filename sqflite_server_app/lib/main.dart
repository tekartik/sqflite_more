import 'package:flutter/material.dart';
import 'package:sqflite_server_app/page/main_page.dart';

void main() => runApp(new SqfliteServerApp());

void run() {
  runApp(new SqfliteServerApp());
}

class SqfliteServerApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: SqfliteServerHomePage(title: 'SQFlite server'),
    );
  }
}

MaterialPageRoute<dynamic> get homePageRoute =>
    MaterialPageRoute<dynamic>(builder: (BuildContext context) {
      return SqfliteServerHomePage(title: 'SQFlite server page');
    });
