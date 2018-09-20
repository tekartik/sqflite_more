import 'package:flutter/material.dart';
import 'package:sqflite_server_app/page/main_page.dart';

void main() => runApp(SqfliteServerApp());

void run() {
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

MaterialPageRoute<dynamic> get homePageRoute =>
    MaterialPageRoute<dynamic>(builder: (BuildContext context) {
      return SqfliteServerHomePage(title: 'SQFlite server page');
    });
