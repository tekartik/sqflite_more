import 'package:sqflite_test_app/src/porter_main.dart';
import 'package:tekartik_test_menu_flutter/test.dart';
import 'package:sqflite_example/main.dart' as example;
import 'src/server_main.dart';

void main() {
  mainMenu(() {
    item('sqlite example app', () {
      example.main();
    });
    group('more', () {
      serverMain();
      porterMain();
    });
  }, showConsole: true);
}
