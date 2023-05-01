import 'package:sqflite_test_app/src/import.dart';
import 'package:sqflite_test_app/src/sqflite_import.dart';

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
