// ignore: implementation_imports
import 'package:sqflite_porter/src/utils.dart';
import 'package:sqflite_test_app/src/porter_main.dart';
import 'package:tekartik_test_menu_flutter/test.dart';
import 'src/server_main.dart';

void main() {
  mainMenu(() {
    dumpSetPrint(write);
    serverMain();
    porterMain();
  });
}
