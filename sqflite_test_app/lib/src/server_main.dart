import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:tekartik_test_menu/test.dart';

int defaultPort = 8501;

void serverMain() {
  menu('server', () {
    SqfliteServer? server;
    item('start', () async {
      server ??= await SqfliteServer.serve(
          port: defaultPort, factory: databaseFactory);
    });
    item('stop', () async {
      await server?.close();
      server = null;
    });
  });
}
